import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/data/mappers/bill_mapper.dart';
import 'package:inventopos/domain/entities/bill.dart';
class HiveBillDao {
  Box<Map> get _box => Hive.box<Map>(HiveBoxes.bills);

  Stream<List<Bill>> watchForUser(String userId) {
    return _box.watch().map((_) => listForUser(userId));
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
    final m = {
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
      if (clientId != null) 'client_id': clientId,
      'sync_status': syncStatus,
    };
    await _box.put(bill.id, m);
  }

  Future<void> putRaw(Map<String, dynamic> row) async {
    await _box.put(row['id'], row);
  }
}
