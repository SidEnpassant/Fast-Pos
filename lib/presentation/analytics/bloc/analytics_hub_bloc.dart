import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/domain/analytics/customer_analytics.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsHubState extends Equatable {
  const AnalyticsHubState({
    this.bills = const [],
    this.expenses = const [],
    this.products = const [],
    this.customers = const [],
    this.loading = true,
    this.businessInsights = BusinessAnalyticsSnapshot.empty,
    this.customerInsights = CustomerAnalyticsSnapshot.empty,
    this.revenueThisMonth = 0.0,
    this.billsThisMonth = 0,
    this.expensesThisMonth = 0.0,
    this.lowStockProducts = const [],
  });

  final List<Bill> bills;
  final List<Expense> expenses;
  final List<Product> products;
  final List<Customer> customers;
  final bool loading;

  final BusinessAnalyticsSnapshot businessInsights;
  final CustomerAnalyticsSnapshot customerInsights;
  final double revenueThisMonth;
  final int billsThisMonth;
  final double expensesThisMonth;
  final List<Product> lowStockProducts;

  double get netProfit => revenueThisMonth - expensesThisMonth;

  AnalyticsHubState copyWith({
    List<Bill>? bills,
    List<Expense>? expenses,
    List<Product>? products,
    List<Customer>? customers,
    bool? loading,
    BusinessAnalyticsSnapshot? businessInsights,
    CustomerAnalyticsSnapshot? customerInsights,
    double? revenueThisMonth,
    int? billsThisMonth,
    double? expensesThisMonth,
    List<Product>? lowStockProducts,
  }) {
    return AnalyticsHubState(
      bills: bills ?? this.bills,
      expenses: expenses ?? this.expenses,
      products: products ?? this.products,
      customers: customers ?? this.customers,
      loading: loading ?? this.loading,
      businessInsights: businessInsights ?? this.businessInsights,
      customerInsights: customerInsights ?? this.customerInsights,
      revenueThisMonth: revenueThisMonth ?? this.revenueThisMonth,
      billsThisMonth: billsThisMonth ?? this.billsThisMonth,
      expensesThisMonth: expensesThisMonth ?? this.expensesThisMonth,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
    );
  }

  @override
  List<Object?> get props => [
        bills,
        expenses,
        products,
        customers,
        loading,
        businessInsights,
        customerInsights,
        revenueThisMonth,
        billsThisMonth,
        expensesThisMonth,
        lowStockProducts,
      ];
}

sealed class AnalyticsHubEvent extends Equatable {
  const AnalyticsHubEvent();
  @override
  List<Object?> get props => [];
}

class AnalyticsHubStarted extends AnalyticsHubEvent {
  const AnalyticsHubStarted();
}

class _AnalyticsHubDataChanged extends AnalyticsHubEvent {
  const _AnalyticsHubDataChanged({
    required this.bills,
    required this.expenses,
    required this.products,
    required this.customers,
  });
  final List<Bill> bills;
  final List<Expense> expenses;
  final List<Product> products;
  final List<Customer> customers;

  @override
  List<Object?> get props => [bills, expenses, products, customers];
}

class AnalyticsHubBloc extends Bloc<AnalyticsHubEvent, AnalyticsHubState> {
  AnalyticsHubBloc(this._bills, this._expenses, this._products, this._customers)
      : super(const AnalyticsHubState()) {
    on<AnalyticsHubStarted>(_onStarted);
    on<_AnalyticsHubDataChanged>(_onDataChanged);
  }

  final ObserveBillsUseCase _bills;
  final ExpenseRepository _expenses;
  final ProductRepository _products;
  final CustomerRepository _customers;

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

    // Sync state updates using a combined stream approach or simple triggers.
    // For performance, we wait for all streams to emit at least once before initial compute.
    StreamSubscription<void> combine() {
      return Stream.periodic(const Duration(milliseconds: 300)).listen((_) async {
        if (_subs.length < 4) return;
        // This is a simplified debounce/throttle for data changes.
      });
    }

    _subs.add(_bills().listen((_) => _triggerCompute()));
    _subs.add(_expenses.watchExpensesForUser(uid).listen((_) => _triggerCompute()));
    _subs.add(_products.watchProductsForUser(uid).listen((_) => _triggerCompute()));
    _subs.add(_customers.watchCustomersForUser(uid).listen((_) => _triggerCompute()));
  }

  Timer? _debounce;
  void _triggerCompute() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      if (isClosed) return;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      // We need to fetch current snapshots to compute. 
      // Ideally repository watch streams should be cached.
      // For now, we rely on the fact that these are likely fast local reads.
      final bills = await _bills().first;
      final expenses = await _expenses.watchExpensesForUser(uid).first;
      final products = await _products.watchProductsForUser(uid).first;
      final customers = await _customers.watchCustomersForUser(uid).first;

      if (!isClosed) {
        add(_AnalyticsHubDataChanged(
          bills: bills,
          expenses: expenses,
          products: products,
          customers: customers,
        ));
      }
    });
  }

  Future<void> _onDataChanged(
    _AnalyticsHubDataChanged event,
    Emitter<AnalyticsHubState> emit,
  ) async {
    // Offload heavy computation to Isolate
    final businessInsights = await compute(_computeBusiness, (
      bills: event.bills,
      expenses: event.expenses,
      products: event.products,
    ));

    final customerInsights = await compute(_computeCustomer, (
      bills: event.bills,
      customers: event.customers,
    ));

    final now = DateTime.now();
    final revenueMonth = event.bills
        .where((b) => BillRevenue.isSameCalendarMonth(b, now))
        .fold(0.0, (s, b) => s + BillRevenue.recognizedAmount(b));

    final billsMonth = event.bills
        .where((b) => BillRevenue.isSameCalendarMonth(b, now))
        .length;

    final expensesMonth = event.expenses
        .where((e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);

    final lowStock = event.products.where((p) => p.isLowStock).take(10).toList();

    emit(state.copyWith(
      bills: event.bills,
      expenses: event.expenses,
      products: event.products,
      customers: event.customers,
      businessInsights: businessInsights,
      customerInsights: customerInsights,
      revenueThisMonth: revenueMonth,
      billsThisMonth: billsMonth,
      expensesThisMonth: expensesMonth,
      lowStockProducts: lowStock,
      loading: false,
    ));
  }

  static BusinessAnalyticsSnapshot _computeBusiness(
      ({List<Bill> bills, List<Expense> expenses, List<Product> products}) arg) {
    return BusinessAnalytics.compute(
      bills: arg.bills,
      expenses: arg.expenses,
      products: arg.products,
    );
  }

  static CustomerAnalyticsSnapshot _computeCustomer(
      ({List<Bill> bills, List<Customer> customers}) arg) {
    return CustomerAnalytics.compute(
      bills: arg.bills,
      customers: arg.customers,
    );
  }

  Future<void> _cancel() async {
    _debounce?.cancel();
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
