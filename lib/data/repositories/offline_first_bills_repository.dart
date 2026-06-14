import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_bill_dao.dart';
import 'package:inventopos/data/mappers/merge_bills.dart';
import 'package:inventopos/data/repositories/bills_repository_impl.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Write-local-first bills repository with Supabase sync via outbox.
class OfflineFirstBillsRepository implements BillsRepository {
  OfflineFirstBillsRepository({
    BillsRepository? remote,
    HiveBillDao? local,
    SyncRepository? sync,
    SupabaseClient? client,
  })  : _remote = remote ?? BillsRepositoryImpl(client: client),
        _local = local ?? HiveBillDao(),
        _sync = sync,
        _client = client ?? Supabase.instance.client;

  final BillsRepository _remote;
  final HiveBillDao _local;
  final SyncRepository? _sync;
  final SupabaseClient _client;
  final _uuid = const Uuid();

  Stream<List<Bill>>? _sharedWatchStream;
  String? _sharedWatchUserId;
  List<Bill>? _cachedBills;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Stream<List<Bill>> watchBillsForCurrentUser() {
    final uid = _userId;
    if (uid == null) {
      _clearSharedWatchStream();
      return const Stream.empty();
    }

    if (_sharedWatchUserId != uid) {
      _clearSharedWatchStream();
      _sharedWatchUserId = uid;
      _cachedBills = _local.listForUser(uid);
      _sharedWatchStream = _buildMergedStream(uid).map((bills) {
        _cachedBills = bills;
        return bills;
      }).asBroadcastStream();
    }

    return replayStream(_sharedWatchStream!, _cachedBills);
  }

  void _clearSharedWatchStream() {
    _sharedWatchStream = null;
    _sharedWatchUserId = null;
    _cachedBills = null;
  }

  Stream<List<Bill>> _buildMergedStream(String uid) {
    final localStream = _local.watchForUser(uid);
    final remoteStream = _remote.watchBillsForCurrentUser();

    return Stream.multi((controller) {
      StreamSubscription<List<Bill>>? localSub;
      StreamSubscription<List<Bill>>? remoteSub;
      List<Bill> localBills = _local.listForUser(uid);
      List<Bill> remoteBills = [];
      List<Bill>? lastEmitted;

      void emitMerged() {
        final byId = <String, Bill>{};
        for (final b in remoteBills) {
          byId[b.id] = b;
        }
        for (final b in localBills) {
          final existing = byId[b.id];
          if (existing == null) {
            byId[b.id] = b;
          } else {
            byId[b.id] = mergeBillSnapshots(existing, b);
          }
        }
        final merged = byId.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (!listEquals(merged, lastEmitted)) {
          lastEmitted = merged;
          controller.add(merged);
        }
      }

      localSub = localStream.listen((bills) {
        localBills = bills;
        emitMerged();
      });
      remoteSub = remoteStream.listen((bills) {
        remoteBills = bills;
        unawaited(_local.mergeAllFromRemote(bills, mergeBillSnapshots));
        emitMerged();
      }, onError: (_) {});

      emitMerged();

      controller.onCancel = () async {
        await localSub?.cancel();
        await remoteSub?.cancel();
      };
    });
  }

  @override
  Future<String> createBill({
    required String businessName,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> productsJson,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethod,
    required String paymentStatus,
    String? clientId,
    String? customerId,
    List<Map<String, dynamic>>? discountBreakdown,
    String? contentHash,
  }) async {
    final uid = _userId;
    if (uid == null) throw StateError('User not authenticated');

    final localId = clientId ?? _uuid.v4();
    final now = DateTime.now();
    final lineItems = productsJson.map((p) {
      final qty = (p['quantity'] as num?)?.toInt() ?? 1;
      final price = (p['price'] as num?)?.toDouble() ?? 0;
      return BillLineItem(
        productName: p['name']?.toString() ?? '',
        quantity: qty,
        totalPrice: price * qty,
      );
    }).toList();

    final bill = Bill(
      id: localId,
      userId: uid,
      businessName: businessName,
      customerName: customerName,
      customerPhone: customerPhone,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      createdAt: now,
      lineItems: lineItems,
    );

    await _local.putFromBill(
      bill,
      clientId: localId,
      syncStatus: 'pending',
    );

    await _sync?.enqueue(
      userId: uid,
      operationType: 'create_bill',
      payload: {
        'client_id': localId,
        'business_name': businessName,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'products': productsJson,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        if (customerId != null) 'customer_id': customerId,
        if (discountBreakdown != null) 'discount_breakdown': discountBreakdown,
        if (contentHash != null) 'content_hash': contentHash,
      },
    );

    if (await (_sync?.isOnline() ?? false)) {
      await _sync?.processOutbox(uid);
    }

    return localId;
  }

  @override
  Future<String> nextBillSequenceNumber() => _remote.nextBillSequenceNumber();

  @override
  Future<List<Bill>> fetchPartialBillsForUser(String userId) =>
      _remote.fetchPartialBillsForUser(userId);

  @override
  Future<void> replaceSignedBillFromLocalFile({
    required String billId,
    required String localFilePath,
  }) =>
      _remote.replaceSignedBillFromLocalFile(
        billId: billId,
        localFilePath: localFilePath,
      );

  @override
  Future<void> deleteBillById(String billId) async {
    await _remote.deleteBillById(billId);
  }

  @override
  Future<void> updateBillPayment({
    required String billId,
    required double newPaidAmount,
    required double totalAmount,
  }) async {
    final status = newPaidAmount >= totalAmount ? 'complete' : 'partial';
    final now = DateTime.now();
    await _local.patch(billId, {
      'paid_amount': newPaidAmount,
      'payment_status': status,
      'last_updated': now.toUtc().toIso8601String(),
    });
    await _remote.updateBillPayment(
      billId: billId,
      newPaidAmount: newPaidAmount,
      totalAmount: totalAmount,
    );
  }

  @override
  Future<void> updatePdfUrl({
    required String billId,
    required String pdfUrl,
    required DateTime pdfUpdatedAt,
  }) async {
    await _local.patch(billId, {
      'pdf_url': pdfUrl,
      'pdf_updated_at': pdfUpdatedAt.toUtc().toIso8601String(),
    });

    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await _remote.updatePdfUrl(
          billId: billId,
          pdfUrl: pdfUrl,
          pdfUpdatedAt: pdfUpdatedAt,
        );
        return;
      } catch (_) {
        await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      }
    }
    // Local Hive already has pdf_url; storage upload succeeded upstream.
  }

  @override
  Future<void> patchLocalBillMetadata(
    String billId,
    Map<String, dynamic> fields,
  ) =>
      _local.patch(billId, fields);

  @override
  Future<Bill?> fetchLocalBillById(String billId) async {
    final uid = _userId;
    if (uid == null) return null;
    return _local.findById(uid, billId);
  }

  @override
  Future<Bill?> fetchBillById(String billId) async {
    final local = await fetchLocalBillById(billId);

    Bill? remote;
    try {
      remote = await _remote.fetchBillById(billId);
    } catch (_) {}

    if (remote != null && local != null) {
      final merged = mergeBillSnapshots(remote, local);
      await _local.putFromBill(merged);
      return merged;
    }
    if (remote != null) {
      await _local.putFromBill(remote);
      return remote;
    }
    return local;
  }

  @override
  Stream<List<Bill>> watchBillsForCustomer({
    required String userId,
    String? customerId,
    String? customerPhone,
  }) =>
      _remote.watchBillsForCustomer(
        userId: userId,
        customerId: customerId,
        customerPhone: customerPhone,
      );
}
