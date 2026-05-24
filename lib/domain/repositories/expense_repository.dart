import 'package:inventopos/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpensesForUser(String userId);

  Future<Expense> createExpense({
    required String userId,
    required String category,
    required double amount,
    required DateTime expenseDate,
    String? note,
  });

  Future<void> deleteExpense(String id);
}
