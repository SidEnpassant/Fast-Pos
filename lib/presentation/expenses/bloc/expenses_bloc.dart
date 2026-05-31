import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/presentation/expenses/bloc/expenses_event.dart';
import 'package:inventopos/presentation/expenses/bloc/expenses_state.dart';

class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  ExpensesBloc(this._expenses) : super(const ExpensesState()) {
    on<ExpensesStarted>(_onStarted);
    on<ExpensesReceived>(_onReceived);
    on<ExpensesPeriodChanged>(_onPeriodChanged);
    on<ExpensesCategoryChanged>(_onCategoryChanged);
    on<ExpenseDeleted>(_onDeleted);
  }

  final ExpenseRepository _expenses;
  StreamSubscription<List<Expense>>? _sub;

  Future<void> _onStarted(
    ExpensesStarted event,
    Emitter<ExpensesState> emit,
  ) async {
    await _sub?.cancel();
    _sub = _expenses.watchExpensesForUser(event.userId).listen(
          (list) => add(ExpensesReceived(list)),
        );
  }

  void _onReceived(ExpensesReceived event, Emitter<ExpensesState> emit) {
    final next = state.copyWith(
      allExpenses: event.expenses,
      loading: false,
    );
    emit(next.copyWith(filtered: _apply(next)));
  }

  void _onPeriodChanged(
    ExpensesPeriodChanged event,
    Emitter<ExpensesState> emit,
  ) {
    final next = state.copyWith(period: event.period);
    emit(next.copyWith(filtered: _apply(next)));
  }

  void _onCategoryChanged(
    ExpensesCategoryChanged event,
    Emitter<ExpensesState> emit,
  ) {
    final next = state.copyWith(
      categoryFilter: event.category,
      clearCategory: event.category == null,
    );
    emit(next.copyWith(filtered: _apply(next)));
  }

  Future<void> _onDeleted(
    ExpenseDeleted event,
    Emitter<ExpensesState> emit,
  ) async {
    await _expenses.deleteExpense(event.id);
  }

  List<Expense> _apply(ExpensesState s) {
    final now = DateTime.now();
    DateTime? start;
    switch (s.period) {
      case ExpensePeriodFilter.week:
        start = now.subtract(const Duration(days: 7));
      case ExpensePeriodFilter.month:
        start = DateTime(now.year, now.month, 1);
      case ExpensePeriodFilter.year:
        start = DateTime(now.year, 1, 1);
      case ExpensePeriodFilter.all:
        start = null;
    }

    return s.allExpenses.where((e) {
      if (start != null && e.expenseDate.isBefore(start)) return false;
      if (s.categoryFilter != null && e.category != s.categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
