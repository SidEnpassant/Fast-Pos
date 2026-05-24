import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.customers);

  @override
  Stream<List<Customer>> watchCustomersForUser(String userId) {
    _pull(userId);
    return _box.watch().map((_) => _list(userId));
  }

  List<Customer> _list(String userId) {
    return _box.values
        .map((m) => _fromMap(Map<String, dynamic>.from(m)))
        .where((c) => c.userId == userId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _pull(String userId) async {
    try {
      final rows =
          await _client.from('customers').select().eq('user_id', userId);
      for (final raw in rows as List) {
        final m = Map<String, dynamic>.from(raw as Map);
        await _box.put(m['id'], m);
      }
    } catch (_) {}
  }

  @override
  Future<Customer?> findByPhone(String userId, String phone) async {
    final normalized = phone.replaceAll(RegExp(r'\s+'), '').trim();
    if (normalized.isEmpty) return null;
    await _pull(userId);
    for (final c in _list(userId)) {
      final cp = (c.phone ?? '').replaceAll(RegExp(r'\s+'), '').trim();
      if (cp == normalized) return c;
    }
    return null;
  }

  @override
  Future<Customer> createCustomer({
    required String userId,
    required String name,
    String? phone,
  }) async {
    final id = _uuid.v4();
    final row = {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'credit_balance': 0,
      'loyalty_points': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      await _client.from('customers').insert(row);
    } catch (_) {}
    await _box.put(id, row);
    return _fromMap(row);
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    final row = {
      'id': customer.id,
      'user_id': customer.userId,
      'name': customer.name,
      'phone': customer.phone,
      'credit_balance': customer.creditBalance,
      'loyalty_points': customer.loyaltyPoints,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      await _client.from('customers').update(row).eq('id', customer.id);
    } catch (_) {}
    await _box.put(customer.id, row);
    return customer;
  }

  @override
  Future<void> recordLedgerEntry({
    required String customerId,
    required String type,
    required double amount,
    String? billId,
    String? note,
  }) async {
    try {
      await _client.from('customer_ledger_entries').insert({
        'customer_id': customerId,
        'bill_id': billId,
        'type': type,
        'amount': amount,
        'note': note,
      });
    } catch (_) {}
    if (type == 'debit') {
      final c = _box.get(customerId);
      if (c != null) {
        final m = Map<String, dynamic>.from(c);
        m['credit_balance'] =
            ((m['credit_balance'] as num?)?.toDouble() ?? 0) + amount;
        await _box.put(customerId, m);
      }
    }
  }

  @override
  Future<void> recordCreditPayment({
    required String customerId,
    required double amount,
  }) async {
    await recordLedgerEntry(
      customerId: customerId,
      type: 'payment',
      amount: amount,
      note: 'Credit payment',
    );
    final c = _box.get(customerId);
    if (c != null) {
      final m = Map<String, dynamic>.from(c);
      m['credit_balance'] =
          ((m['credit_balance'] as num?)?.toDouble() ?? 0) - amount;
      await _box.put(customerId, m);
    }
  }

  Customer _fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        creditBalance: (m['credit_balance'] as num?)?.toDouble() ?? 0,
        loyaltyPoints: (m['loyalty_points'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
