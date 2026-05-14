/// Supabase-backed stream of completed rows from `transactions`.
abstract class TransactionsRepository {
  Stream<List<Map<String, dynamic>>> getCompleteTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  });

  /// Inserts a transaction row linked to the current business user.
  Future<void> recordBillTransaction({
    required String customerName,
    required double amount,
    required bool isComplete,
  });
}
