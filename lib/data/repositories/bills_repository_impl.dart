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
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    final inserted = await _client
        .from('bills')
        .insert({
          'user_id': user.id,
          'business_name': businessName,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'products': productsJson,
          'total_amount': totalAmount,
          'paid_amount': paidAmount,
          'payment_method': paymentMethod,
          'payment_status': paymentStatus,
        })
        .select('id')
        .single();
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
}
