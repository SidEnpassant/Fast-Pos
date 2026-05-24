import 'dart:async';

import 'package:inventopos/data/local/hive/hive_bill_dao.dart';
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

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Stream<List<Bill>> watchBillsForCurrentUser() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    final localStream = _local.watchForUser(uid);
    final remoteStream = _remote.watchBillsForCurrentUser();

    return Stream.multi((controller) {
      StreamSubscription<List<Bill>>? localSub;
      StreamSubscription<List<Bill>>? remoteSub;
      List<Bill> localBills = _local.listForUser(uid);
      List<Bill> remoteBills = [];

      void emitMerged() {
        final byId = <String, Bill>{};
        for (final b in remoteBills) {
          byId[b.id] = b;
        }
        for (final b in localBills) {
          if (!byId.containsKey(b.id)) byId[b.id] = b;
        }
        final merged = byId.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(merged);
      }

      localSub = localStream.listen((bills) {
        localBills = bills;
        emitMerged();
      });
      remoteSub = remoteStream.listen((bills) {
        remoteBills = bills;
        for (final b in bills) {
          unawaited(_local.putFromBill(b));
        }
        emitMerged();
      }, onError: (_) {});

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
      unawaited(_sync?.processOutbox(uid));
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
  }) =>
      _remote.updateBillPayment(
        billId: billId,
        newPaidAmount: newPaidAmount,
        totalAmount: totalAmount,
      );
}
