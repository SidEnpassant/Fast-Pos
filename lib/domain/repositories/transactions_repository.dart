/// Supabase-backed stream of completed rows from `transactions`.
abstract class TransactionsRepository {
  Stream<List<Map<String, dynamic>>> getCompleteTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  });
}
