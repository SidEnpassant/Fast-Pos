import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/supabase/guard_supabase_postgres_stream.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/repositories/credit_note_repository.dart';
import '../mappers/credit_note_mapper.dart';

class CreditNoteRepositoryImpl implements CreditNoteRepository {
  CreditNoteRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<CreditNote> createCreditNote(CreditNote creditNote) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');

    final cnId = creditNote.id.isEmpty
        ? const Uuid().v4()
        : creditNote.id;

    await _client.rpc('process_return', params: {
      'p_user_id': user.id,
      'p_cn_id': cnId,
      'p_bill_id': creditNote.originalBillId,
      'p_cn_number': creditNote.creditNoteNumber,
      'p_customer_id': creditNote.customerId,
      'p_customer_name': creditNote.customerName ?? '',
      'p_total_refund': creditNote.totalRefundAmount,
      'p_refund_method': creditNote.refundMethod,
      'p_reason': creditNote.reason ?? '',
      'p_lines': creditNote.lineItems.map((e) => {
        'product_id': e.productId,
        'product_name': e.productName,
        'quantity': e.quantity,
        'unit_price': e.unitPrice,
        'line_total': e.lineTotal,
        'gst_amount': e.gstAmount,
      }).toList(),
    });

    final note = await getCreditNoteById(cnId);
    if (note == null) throw StateError('Failed to fetch created credit note');
    return note;
  }

  @override
  Stream<List<CreditNote>> watchCreditNotesForUser(String userId) {
    return guardSupabasePostgresStream(
      _client
          .from('credit_notes')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((rows) => rows.map(CreditNoteMapper.fromSupabaseRow).toList()),
    );
  }

  @override
  Future<CreditNote?> getCreditNoteById(String id) async {
    final row = await _client.from('credit_notes').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return CreditNoteMapper.fromSupabaseRow(row);
  }

  @override
  Future<List<CreditNote>> getCreditNotesForBill(String billId) async {
    final rows = await _client.from('credit_notes').select().eq('original_bill_id', billId);
    return (rows as List).map((row) => CreditNoteMapper.fromSupabaseRow(Map<String, dynamic>.from(row))).toList();
  }

  @override
  Future<List<CreditNote>> getCreditNotesForCustomer(String customerId) async {
    final rows = await _client.from('credit_notes').select().eq('customer_id', customerId);
    return (rows as List).map((row) => CreditNoteMapper.fromSupabaseRow(Map<String, dynamic>.from(row))).toList();
  }

  @override
  Future<String> generateNextCreditNoteNumber() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    final n = await _client.rpc(
      'increment_credit_note_number',
      params: {'p_user_id': user.id},
    );
    return n.toString();
  }
}
