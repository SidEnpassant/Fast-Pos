import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/data/mappers/bill_mapper.dart';
import 'package:inventopos/domain/entities/bill.dart';
class HiveBillDao {
  Box<Map> get _box => Hive.box<Map>(HiveBoxes.bills);

  Stream<List<Bill>> watchForUser(String userId) {
    return hiveWatchStream(
      events: _box.watch(),
      read: () => listForUser(userId),
    );
  }

  List<Bill> listForUser(String userId) {
    return _box.values
        .map((m) => BillMapper.fromSupabaseRow(Map<String, dynamic>.from(m)))
        .where((b) => b.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> putFromBill(
    Bill bill, {
    String? clientId,
    String syncStatus = 'synced',
  }) async {
    await _box.put(
      bill.id,
      _toMap(bill, clientId: clientId, syncStatus: syncStatus),
    );
  }

  Map<String, dynamic> _toMap(
    Bill bill, {
    String? clientId,
    String syncStatus = 'synced',
  }) {
    return {
      'id': bill.id,
      'user_id': bill.userId,
      'business_name': bill.businessName,
      'customer_name': bill.customerName,
      'customer_phone': bill.customerPhone,
      'products': bill.lineItems
          .map((l) => {
                'name': l.productName,
                'quantity': l.quantity,
                'price': l.quantity > 0 ? l.totalPrice / l.quantity : 0,
              })
          .toList(),
      'total_amount': bill.totalAmount,
      'paid_amount': bill.paidAmount,
      'payment_method': bill.paymentMethod,
      'payment_status': bill.paymentStatus,
      'created_at': bill.createdAt.toUtc().toIso8601String(),
      'last_updated': bill.lastUpdated?.toUtc().toIso8601String(),
      'signed_bill_url': bill.signedBillUrl,
      'last_signed_bill_update':
          bill.lastSignedBillUpdate?.toUtc().toIso8601String(),
      'pdf_url': bill.pdfUrl,
      'pdf_updated_at': bill.pdfUpdatedAt?.toUtc().toIso8601String(),
      if (bill.displayBillNumber != null)
        'display_bill_number': bill.displayBillNumber,
      'customer_id': bill.customerId,
      if (clientId != null) 'client_id': clientId,
      'sync_status': syncStatus,
    };
  }

  Bill? findById(String userId, String billId) {
    final raw = _box.get(billId);
    if (raw == null) return null;
    final bill = BillMapper.fromSupabaseRow(Map<String, dynamic>.from(raw));
    if (bill.userId != userId) return null;
    return bill;
  }

  Future<void> putRaw(Map<String, dynamic> row) async {
    await _box.put(row['id'], row);
  }

  Future<void> patch(String billId, Map<String, dynamic> fields) async {
    final existing = _box.get(billId);
    if (existing == null) return;
    final m = Map<String, dynamic>.from(existing);
    m.addAll(fields);
    await _box.put(billId, m);
  }

  Future<void> mergeFromRemote(
    Bill remote,
    Bill Function(Bill remote, Bill local) merge,
  ) async {
    final existing = _box.get(remote.id);
    if (existing == null) {
      await putFromBill(remote);
      return;
    }
    final local = BillMapper.fromSupabaseRow(
      Map<String, dynamic>.from(existing),
    );
    await putFromBill(merge(remote, local));
  }

  Future<void> mergeAllFromRemote(
    List<Bill> remotes,
    Bill Function(Bill remote, Bill local) merge,
  ) async {
    final batch = <String, Map>{};
    for (final remote in remotes) {
      final existing = _box.get(remote.id);
      if (existing == null) {
        batch[remote.id] = _toMap(remote);
      } else {
        final local = BillMapper.fromSupabaseRow(
          Map<String, dynamic>.from(existing),
        );
        batch[remote.id] = _toMap(merge(remote, local));
      }
    }
    if (batch.isNotEmpty) {
      await _box.putAll(batch);
    }
  }
}
