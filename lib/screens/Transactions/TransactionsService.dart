import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getCompleteTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user found');
    }

    return _client
        .from('transactions')
        .stream(primaryKey: ['id']).eq('business_id', userId).map((rows) {
      var list = rows.where((r) => r['is_complete'] == true).toList();

      if (startDate != null && endDate != null) {
        final end = endDate.add(const Duration(days: 1));
        list = list.where((r) {
          final d = DateTime.tryParse(r['created_at'].toString());
          if (d == null) return false;
          return !d.isBefore(startDate) && d.isBefore(end);
        }).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        list = list.where((r) {
          final name = (r['customer_name'] as String?)?.toLowerCase() ?? '';
          return name.contains(q);
        }).toList();
      }

      list.sort((a, b) {
        final da = DateTime.tryParse(a['created_at'].toString());
        final db = DateTime.tryParse(b['created_at'].toString());
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });

      return list;
    });
  }

  Future<void> debugCheckTransactions() async {
    try {
      final userId = _client.auth.currentUser?.id;
      print('Checking transactions for user: $userId');

      final list = await _client
          .from('transactions')
          .select()
          .eq('business_id', userId ?? '');

      print('Total transactions found: ${list.length}');
      for (var row in list) {
        print('Transaction: $row');
      }
    } catch (e) {
      print('Debug Error: $e');
    }
  }
}
