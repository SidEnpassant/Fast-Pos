import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/domain/analytics/customer_analytics.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';
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
    this.monthlyRevenues = const {},
    this.monthlyTransactions = const {},
    this.sortedMonths = const [],
    this.selectedMonth,
    this.showChart = true,
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

  final Map<String, double> monthlyRevenues;
  final Map<String, int> monthlyTransactions;
  final List<String> sortedMonths;
  final String? selectedMonth;
  final bool showChart;

  double get netProfit => revenueThisMonth - expensesThisMonth;

  bool get hasRevenueData => monthlyRevenues.isNotEmpty;

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
    Map<String, double>? monthlyRevenues,
    Map<String, int>? monthlyTransactions,
    List<String>? sortedMonths,
    String? selectedMonth,
    bool? showChart,
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
      monthlyRevenues: monthlyRevenues ?? this.monthlyRevenues,
      monthlyTransactions: monthlyTransactions ?? this.monthlyTransactions,
      sortedMonths: sortedMonths ?? this.sortedMonths,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      showChart: showChart ?? this.showChart,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        businessInsights,
        customerInsights,
        revenueThisMonth,
        billsThisMonth,
        expensesThisMonth,
        lowStockProducts.length,
        monthlyRevenues,
        monthlyTransactions,
        sortedMonths,
        selectedMonth,
        showChart,
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

class AnalyticsHubMonthSelected extends AnalyticsHubEvent {
  const AnalyticsHubMonthSelected(this.month);

  final String month;

  @override
  List<Object?> get props => [month];
}

class AnalyticsHubChartToggled extends AnalyticsHubEvent {
  const AnalyticsHubChartToggled();
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

typedef _AnalyticsComputeInput = ({
  List<Bill> bills,
  List<Expense> expenses,
  List<Product> products,
  List<Customer> customers,
});

typedef _AnalyticsComputeOutput = ({
  BusinessAnalyticsSnapshot business,
  CustomerAnalyticsSnapshot customer,
  Map<String, double> monthlyRevenues,
  Map<String, int> monthlyTransactions,
  List<String> sortedMonths,
});

class AnalyticsHubBloc extends Bloc<AnalyticsHubEvent, AnalyticsHubState> {
  AnalyticsHubBloc(this._bills, this._expenses, this._products, this._customers)
      : super(
          AnalyticsHubState(
            selectedMonth: DateFormat('MMM yyyy').format(DateTime.now()),
          ),
        ) {
    on<AnalyticsHubStarted>(_onStarted);
    on<_AnalyticsHubDataChanged>(_onDataChanged);
    on<AnalyticsHubMonthSelected>(_onMonthSelected);
    on<AnalyticsHubChartToggled>(_onChartToggled);
  }

  final ObserveBillsUseCase _bills;
  final ExpenseRepository _expenses;
  final ProductRepository _products;
  final CustomerRepository _customers;

  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _debounce;
  int _computeGeneration = 0;
  String? _activeUserId;
  bool _pendingImmediateCompute = true;

  List<Bill> _latestBills = const [];
  List<Expense> _latestExpenses = const [];
  List<Product> _latestProducts = const [];
  List<Customer> _latestCustomers = const [];

  void setSelectedMonth(String? month) {
    if (month == null) return;
    add(AnalyticsHubMonthSelected(month));
  }

  void toggleChartTable() => add(const AnalyticsHubChartToggled());

  Future<void> _onStarted(
    AnalyticsHubStarted event,
    Emitter<AnalyticsHubState> emit,
  ) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      emit(state.copyWith(loading: false));
      return;
    }

    if (_activeUserId == uid && _subs.isNotEmpty) {
      _scheduleCompute();
      return;
    }

    await _cancel();
    _activeUserId = uid;

    _subs.add(_bills().listen((bills) {
      _latestBills = bills;
      _scheduleCompute();
    }));
    _subs.add(_expenses.watchExpensesForUser(uid).listen((expenses) {
      _latestExpenses = expenses;
      _scheduleCompute();
    }));
    _subs.add(_products.watchProductsForUser(uid).listen((products) {
      _latestProducts = products;
      _scheduleCompute();
    }));
    _subs.add(_customers.watchCustomersForUser(uid).listen((customers) {
      _latestCustomers = customers;
      _scheduleCompute();
    }));
  }

  void _scheduleCompute() {
    _debounce?.cancel();
    if (_pendingImmediateCompute) {
      _pendingImmediateCompute = false;
      if (isClosed) return;
      add(_AnalyticsHubDataChanged(
        bills: _latestBills,
        expenses: _latestExpenses,
        products: _latestProducts,
        customers: _latestCustomers,
      ));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (isClosed) return;
      add(_AnalyticsHubDataChanged(
        bills: _latestBills,
        expenses: _latestExpenses,
        products: _latestProducts,
        customers: _latestCustomers,
      ));
    });
  }

  Future<void> _onDataChanged(
    _AnalyticsHubDataChanged event,
    Emitter<AnalyticsHubState> emit,
  ) async {
    final generation = ++_computeGeneration;

    final insights = await compute(_computeInsights, (
      bills: event.bills,
      expenses: event.expenses,
      products: event.products,
      customers: event.customers,
    ));

    if (isClosed || generation != _computeGeneration) return;

    final now = DateTime.now();
    final revenueMonth = event.bills
        .where((b) => BillRevenue.isSameCalendarMonth(b, now))
        .fold(0.0, (s, b) => s + BillRevenue.recognizedAmount(b));

    final billsMonth = event.bills
        .where((b) => BillRevenue.isSameCalendarMonth(b, now))
        .length;

    final expensesMonth = event.expenses
        .where((e) =>
            e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);

    final lowStock = event.products.where((p) => p.isLowStock).take(10).toList();

    var selected = state.selectedMonth;
    if (insights.sortedMonths.isEmpty) {
      selected = null;
    } else if (selected == null || !insights.sortedMonths.contains(selected)) {
      selected = insights.sortedMonths.first;
    }

    emit(state.copyWith(
      bills: event.bills,
      expenses: event.expenses,
      products: event.products,
      customers: event.customers,
      businessInsights: insights.business,
      customerInsights: insights.customer,
      revenueThisMonth: revenueMonth,
      billsThisMonth: billsMonth,
      expensesThisMonth: expensesMonth,
      lowStockProducts: lowStock,
      monthlyRevenues: insights.monthlyRevenues,
      monthlyTransactions: insights.monthlyTransactions,
      sortedMonths: insights.sortedMonths,
      selectedMonth: selected,
      loading: false,
    ));
  }

  void _onMonthSelected(
    AnalyticsHubMonthSelected event,
    Emitter<AnalyticsHubState> emit,
  ) {
    emit(state.copyWith(selectedMonth: event.month));
  }

  void _onChartToggled(
    AnalyticsHubChartToggled event,
    Emitter<AnalyticsHubState> emit,
  ) {
    emit(state.copyWith(showChart: !state.showChart));
  }

  static _AnalyticsComputeOutput _computeInsights(_AnalyticsComputeInput input) {
    final monthlyRevenues = BusinessAnalytics.monthlyRevenueMap(input.bills);
    final monthlyTransactions =
        BusinessAnalytics.monthlyTransactionMap(input.bills);
    final sortedMonths = monthlyRevenues.keys.toList()
      ..sort(
        (a, b) => DateFormat('MMM yyyy')
            .parse(b)
            .compareTo(DateFormat('MMM yyyy').parse(a)),
      );

    return (
      business: BusinessAnalytics.compute(
        bills: input.bills,
        expenses: input.expenses,
        products: input.products,
      ),
      customer: CustomerAnalytics.compute(
        bills: input.bills,
        customers: input.customers,
      ),
      monthlyRevenues: monthlyRevenues,
      monthlyTransactions: monthlyTransactions,
      sortedMonths: sortedMonths,
    );
  }

  Future<void> _cancel() async {
    _debounce?.cancel();
    _computeGeneration++;
    _pendingImmediateCompute = true;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _activeUserId = null;
  }

  @override
  Future<void> close() async {
    await _cancel();
    return super.close();
  }
}
