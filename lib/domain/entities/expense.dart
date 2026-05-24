import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.note,
    required this.createdAt,
    this.syncStatus = 'synced',
  });

  final String id;
  final String userId;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String? note;
  final DateTime createdAt;
  final String syncStatus;

  @override
  List<Object?> get props =>
      [id, userId, category, amount, expenseDate, note, createdAt, syncStatus];
}
