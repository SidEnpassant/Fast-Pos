import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/expense.dart';

enum ExpensePeriodFilter { week, month, year, all }

sealed class ExpensesEvent extends Equatable {
  const ExpensesEvent();

  @override
  List<Object?> get props => [];
}

class ExpensesStarted extends ExpensesEvent {
  const ExpensesStarted(this.userId);
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class ExpensesReceived extends ExpensesEvent {
  const ExpensesReceived(this.expenses);
  final List<Expense> expenses;
  @override
  List<Object?> get props => [expenses];
}

class ExpensesPeriodChanged extends ExpensesEvent {
  const ExpensesPeriodChanged(this.period);
  final ExpensePeriodFilter period;
  @override
  List<Object?> get props => [period];
}

class ExpensesCategoryChanged extends ExpensesEvent {
  const ExpensesCategoryChanged(this.category);
  final String? category;
  @override
  List<Object?> get props => [category];
}

class ExpenseDeleted extends ExpensesEvent {
  const ExpenseDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
