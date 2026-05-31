import 'dart:io';

import 'package:inventopos/core/supabase/guard_supabase_postgres_stream.dart';
import 'package:inventopos/data/mappers/bill_mapper.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillsRepositoryImpl implements BillsRepository {
  BillsRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<List<Bill>> watchBillsForCurrentUser() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream.empty();
    }
    return guardSupabasePostgresStream(
      _client.from('bills').stream(primaryKey: ['id']).eq('user_id', uid).map(
            (rows) => rows.map(BillMapper.fromSupabaseRow).toList(),
          ),
    );
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
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    final row = <String, dynamic>{
      if (clientId != null) 'id': clientId,
      'user_id': user.id,
      'business_name': businessName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'products': productsJson,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      if (clientId != null) 'client_id': clientId,
      if (customerId != null) 'customer_id': customerId,
      if (discountBreakdown != null) 'discount_breakdown': discountBreakdown,
      if (contentHash != null) 'content_hash': contentHash,
      'sync_status': 'synced',
    };
    final inserted =
        await _client.from('bills').insert(row).select('id').single();
    return inserted['id'] as String;
  }

  @override
  Future<String> nextBillSequenceNumber() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    final n = await _client.rpc(
      'increment_bill_number',
      params: {'p_user_id': user.id},
    );
    return n.toString();
  }

  @override
  Future<List<Bill>> fetchPartialBillsForUser(String userId) async {
    final rows = await _client
        .from('bills')
        .select()
        .eq('user_id', userId)
        .eq('payment_status', 'partial');
    return (rows as List<dynamic>)
        .map((e) => BillMapper.fromSupabaseRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> replaceSignedBillFromLocalFile({
    required String billId,
    required String localFilePath,
  }) async {
    final bucket = _client.storage.from('signed_bills');
    try {
      await bucket.remove(['$billId.jpg']);
    } catch (_) {}
    await bucket.upload(
      '$billId.jpg',
      File(localFilePath),
      fileOptions: const FileOptions(upsert: true),
    );
    final downloadUrl = bucket.getPublicUrl('$billId.jpg');
    await _client.from('bills').update({
      'signed_bill_url': downloadUrl,
      'last_signed_bill_update': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', billId);
  }

  @override
  Future<void> deleteBillById(String billId) async {
    try {
      await _client.storage.from('signed_bills').remove(['$billId.jpg']);
    } catch (_) {}
    await _client.from('bills').delete().eq('id', billId);
  }

  @override
  Future<void> updateBillPayment({
    required String billId,
    required double newPaidAmount,
    required double totalAmount,
  }) async {
    await _client.from('bills').update({
      'paid_amount': newPaidAmount,
      'payment_status':
          newPaidAmount >= totalAmount ? 'complete' : 'partial',
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', billId);
  }

  @override
  Future<void> updatePdfUrl({
    required String billId,
    required String pdfUrl,
    required DateTime pdfUpdatedAt,
  }) async {
    await _client.from('bills').update({
      'pdf_url': pdfUrl,
      'pdf_updated_at': pdfUpdatedAt.toUtc().toIso8601String(),
    }).eq('id', billId);
  }

  @override
  Future<void> patchLocalBillMetadata(
    String billId,
    Map<String, dynamic> fields,
  ) async {}

  @override
  Future<Bill?> fetchLocalBillById(String billId) async => null;

  @override
  Future<Bill?> fetchBillById(String billId) async {
    final row = await _client.from('bills').select().eq('id', billId).maybeSingle();
    if (row == null) return null;
    return BillMapper.fromSupabaseRow(Map<String, dynamic>.from(row));
  }

  @override
  Stream<List<Bill>> watchBillsForCustomer({
    required String userId,
    String? customerId,
    String? customerPhone,
  }) {
    return watchBillsForCurrentUser().map((bills) {
      return bills.where((b) {
        if (customerId != null && b.customerId == customerId) return true;
        if (customerPhone != null &&
            customerPhone.isNotEmpty &&
            b.customerPhone == customerPhone) {
          return true;
        }
        return false;
      }).toList();
    });
  }
}
