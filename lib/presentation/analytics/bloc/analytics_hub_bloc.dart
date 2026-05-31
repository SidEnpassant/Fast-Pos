import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsHubState extends Equatable {
  const AnalyticsHubState({
    this.bills = const [],
    this.expenses = const [],
    this.products = const [],
    this.loading = true,
  });

  final List<Bill> bills;
  final List<Expense> expenses;
  final List<Product> products;
  final bool loading;

  double get revenueThisMonth {
    final now = DateTime.now();
    return bills
        .where((b) => BillRevenue.isSameCalendarMonth(b, now))
        .fold(0.0, (s, b) => s + BillRevenue.recognizedAmount(b));
  }

  int get billsThisMonth {
    final now = DateTime.now();
    return bills.where((b) => BillRevenue.isSameCalendarMonth(b, now)).length;
  }

  double get expensesThisMonth {
    final now = DateTime.now();
    return expenses
        .where((e) =>
            e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get netProfit => revenueThisMonth - expensesThisMonth;

  List<Product> get lowStockProducts =>
      products.where((p) => p.isLowStock).take(10).toList();

  AnalyticsHubState copyWith({
    List<Bill>? bills,
    List<Expense>? expenses,
    List<Product>? products,
    bool? loading,
  }) {
    return AnalyticsHubState(
      bills: bills ?? this.bills,
      expenses: expenses ?? this.expenses,
      products: products ?? this.products,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [bills, expenses, products, loading];
}

sealed class AnalyticsHubEvent extends Equatable {
  const AnalyticsHubEvent();
  @override
  List<Object?> get props => [];
}

class AnalyticsHubStarted extends AnalyticsHubEvent {
  const AnalyticsHubStarted();
}

class AnalyticsHubBillsReceived extends AnalyticsHubEvent {
  const AnalyticsHubBillsReceived(this.bills);
  final List<Bill> bills;
  @override
  List<Object?> get props => [bills];
}

class AnalyticsHubExpensesReceived extends AnalyticsHubEvent {
  const AnalyticsHubExpensesReceived(this.expenses);
  final List<Expense> expenses;
  @override
  List<Object?> get props => [expenses];
}

class AnalyticsHubProductsReceived extends AnalyticsHubEvent {
  const AnalyticsHubProductsReceived(this.products);
  final List<Product> products;
  @override
  List<Object?> get props => [products];
}

class AnalyticsHubBloc extends Bloc<AnalyticsHubEvent, AnalyticsHubState> {
  AnalyticsHubBloc(this._bills, this._expenses, this._products)
      : super(const AnalyticsHubState()) {
    on<AnalyticsHubStarted>(_onStarted);
    on<AnalyticsHubBillsReceived>(_onBills);
    on<AnalyticsHubExpensesReceived>(_onExpenses);
    on<AnalyticsHubProductsReceived>(_onProducts);
  }

  final ObserveBillsUseCase _bills;
  final ExpenseRepository _expenses;
  final ProductRepository _products;

  final List<StreamSubscription<dynamic>> _subs = [];

  Future<void> _onStarted(
    AnalyticsHubStarted event,
    Emitter<AnalyticsHubState> emit,
  ) async {
    await _cancel();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      emit(state.copyWith(loading: false));
      return;
    }
    _subs.add(_bills().listen((b) => add(AnalyticsHubBillsReceived(b))));
    _subs.add(
      _expenses.watchExpensesForUser(uid).listen(
            (e) => add(AnalyticsHubExpensesReceived(e)),
          ),
    );
    _subs.add(
      _products.watchProductsForUser(uid).listen(
            (p) => add(AnalyticsHubProductsReceived(p)),
          ),
    );
  }

  void _onBills(AnalyticsHubBillsReceived e, Emitter<AnalyticsHubState> emit) {
    emit(state.copyWith(bills: e.bills, loading: false));
  }

  void _onExpenses(
    AnalyticsHubExpensesReceived e,
    Emitter<AnalyticsHubState> emit,
  ) {
    emit(state.copyWith(expenses: e.expenses));
  }

  void _onProducts(
    AnalyticsHubProductsReceived e,
    Emitter<AnalyticsHubState> emit,
  ) {
    emit(state.copyWith(products: e.products));
  }

  Future<void> _cancel() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  @override
  Future<void> close() async {
    await _cancel();
    return super.close();
  }
}
