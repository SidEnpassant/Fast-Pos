import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:inventopos/data/local/hive/hive_outbox_dao.dart';
import 'package:inventopos/data/repositories/bills_repository_impl.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    SupabaseClient? client,
    HiveOutboxDao? outbox,
    Connectivity? connectivity,
  })  : _client = client ?? Supabase.instance.client,
        _outbox = outbox ?? HiveOutboxDao(),
        _connectivity = connectivity ?? Connectivity();

  final SupabaseClient _client;
  final HiveOutboxDao _outbox;
  final Connectivity _connectivity;
  final Map<String, Future<int>> _processInFlight = {};

  @override
  Stream<int> watchPendingOutboxCount(String userId) =>
      _outbox.watchPendingCount(userId);

  @override
  Future<void> enqueue({
    required String userId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) =>
      _outbox.enqueue(
        userId: userId,
        operationType: operationType,
        payload: payload,
      );

  @override
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Future<int> processOutbox(String userId) async {
    if (!await isOnline()) return 0;

    final inFlight = _processInFlight[userId];
    if (inFlight != null) return inFlight;

    final future = _processOutboxOnce(userId);
    _processInFlight[userId] = future;
    try {
      return await future;
    } finally {
      if (identical(_processInFlight[userId], future)) {
        _processInFlight.remove(userId);
      }
    }
  }

  Future<int> _processOutboxOnce(String userId) async {
    var synced = 0;
    final pending = _outbox.pendingForUser(userId);
    final remote = BillsRepositoryImpl(client: _client);

    for (final entry in pending) {
      final op = entry['operation_type'] as String;
      final payload =
          jsonDecode(entry['payload_json'] as String) as Map<String, dynamic>;
      try {
        switch (op) {
          case 'create_bill':
            await remote.createBill(
              businessName: payload['business_name'] as String,
              customerName: payload['customer_name'] as String,
              customerPhone: payload['customer_phone'] as String,
              productsJson:
                  List<Map<String, dynamic>>.from(payload['products'] as List),
              totalAmount: (payload['total_amount'] as num).toDouble(),
              paidAmount: (payload['paid_amount'] as num).toDouble(),
              paymentMethod: payload['payment_method'] as String,
              paymentStatus: payload['payment_status'] as String,
              clientId: payload['client_id'] as String?,
              customerId: payload['customer_id'] as String?,
              discountBreakdown: payload['discount_breakdown'] != null
                  ? List<Map<String, dynamic>>.from(
                      payload['discount_breakdown'] as List,
                    )
                  : null,
              contentHash: payload['content_hash'] as String?,
            );
            break;
          case 'bulk_upsert_products':
            await _client.rpc('bulk_upsert_products', params: {
              'p_user_id': userId,
              'p_json': payload['products'],
            });
            break;
          case 'decrement_stock':
            await _client.rpc(
              'decrement_stock_for_bill',
              params: {
                'p_bill_id': payload['bill_id'],
                'p_lines': payload['lines'],
              },
            );
            break;
          default:
            break;
        }
        await _outbox.markSynced(entry['id'] as String);
        synced++;
      } catch (_) {
        await _outbox.incrementRetry(entry['id'] as String);
      }
    }
    return synced;
  }
}
