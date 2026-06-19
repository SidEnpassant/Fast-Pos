import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/presentation/expenses/bloc/expenses_event.dart';

class ExpensesState extends Equatable {
  const ExpensesState({
    this.allExpenses = const [],
    this.filtered = const [],
    this.period = ExpensePeriodFilter.month,
    this.categoryFilter,
    this.loading = true,
  });

  final List<Expense> allExpenses;
  final List<Expense> filtered;
  final ExpensePeriodFilter period;
  final String? categoryFilter;
  final bool loading;

  double get periodTotal => filtered.fold(0.0, (s, e) => s + e.amount);

  int get periodCount => filtered.length;

  String? get topCategory {
    if (filtered.isEmpty) return null;
    final totals = <String, double>{};
    for (final e in filtered) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<String> get categories =>
      allExpenses.map((e) => e.category).toSet().toList()..sort();

  ExpensesState copyWith({
    List<Expense>? allExpenses,
    List<Expense>? filtered,
    ExpensePeriodFilter? period,
    String? categoryFilter,
    bool? loading,
    bool clearCategory = false,
  }) =>
      ExpensesState(
        allExpenses: allExpenses ?? this.allExpenses,
        filtered: filtered ?? this.filtered,
        period: period ?? this.period,
        categoryFilter:
            clearCategory ? null : (categoryFilter ?? this.categoryFilter),
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props =>
      [allExpenses, filtered, period, categoryFilter, loading];
}
