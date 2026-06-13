import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_event.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';

class DashboardHubBloc extends Bloc<DashboardHubEvent, DashboardHubState> {
  DashboardHubBloc(
    this._observeBills,
    this._profileRepository,
    this._products,
    this._expenses,
    this._customers,
    this._sync,
    this._notifications,
  ) : super(const DashboardHubState()) {
    on<DashboardHubStarted>(_onStarted);
    on<DashboardHubBillsReceived>(_onBills);
    on<DashboardHubProfileReceived>(_onProfile);
    on<DashboardHubProductsReceived>(_onProducts);
    on<DashboardHubExpensesReceived>(_onExpenses);
    on<DashboardHubCustomersReceived>(_onCustomers);
    on<DashboardHubPendingSyncChanged>(_onPending);
    on<DashboardHubNotificationsReceived>(_onNotifications);
    on<DashboardHubConnectivityChanged>(_onConnectivity);
    on<DashboardHubAiUnreadChanged>(_onAiUnread);
    on<DashboardHubRecomputeRequested>(_onRecompute);
  }

  final ObserveBillsUseCase _observeBills;
  final ProfileRepository _profileRepository;
  final ProductRepository _products;
  final ExpenseRepository _expenses;
  final CustomerRepository _customers;
  final SyncRepository _sync;
  final NotificationsRepository _notifications;

  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _debounce;
  int _computeGeneration = 0;
  String? _activeUserId;
  bool _pendingImmediateRecompute = true;
  bool _gotBills = false;
  bool _gotProducts = false;
  bool _gotExpenses = false;
  bool _gotCustomers = false;
  bool _gotMetrics = false;

  void _resetInitialLoadFlags() {
    _gotBills = false;
    _gotProducts = false;
    _gotExpenses = false;
    _gotCustomers = false;
    _gotMetrics = false;
    _pendingImmediateRecompute = true;
  }

  void _markRefreshLoadFlagsFromState() {
    _gotBills = state.bills != null;
    _gotProducts = true;
    _gotExpenses = true;
    _gotCustomers = true;
    _gotMetrics = false;
    _pendingImmediateRecompute = true;
  }

  void _maybeFinishInitialLoad(Emitter<DashboardHubState> emit) {
    if (!_gotBills ||
        !_gotProducts ||
        !_gotExpenses ||
        !_gotCustomers ||
        !_gotMetrics) {
      return;
    }
    if (!state.loading) return;
    emit(state.copyWith(loading: false));
  }

  Future<void> _onStarted(
    DashboardHubStarted event,
    Emitter<DashboardHubState> emit,
  ) async {
    if (_activeUserId == event.userId && _subs.isNotEmpty) {
      _markRefreshLoadFlagsFromState();
      emit(state.copyWith(loading: true));
      _requestRecompute();
      return;
    }

    await _cancelSubs();
    _activeUserId = event.userId;
    _resetInitialLoadFlags();
    emit(state.copyWith(loading: true));

    _subs.add(
      _observeBills().listen((b) => add(DashboardHubBillsReceived(b))),
    );

    final profileStream = _profileRepository.watchProfileForCurrentUser();
    if (profileStream != null) {
      _subs.add(
        profileStream.listen((p) => add(DashboardHubProfileReceived(p))),
      );
    }

    _subs.add(
      _products.watchProductsForUser(event.userId).listen(
            (p) => add(DashboardHubProductsReceived(p)),
          ),
    );
    _subs.add(
      _expenses.watchExpensesForUser(event.userId).listen(
            (e) => add(DashboardHubExpensesReceived(e)),
          ),
    );
    _subs.add(
      _customers.watchCustomersForUser(event.userId).listen(
            (c) => add(DashboardHubCustomersReceived(c)),
          ),
    );
    _subs.add(
      _sync.watchPendingOutboxCount(event.userId).listen(
            (n) => add(DashboardHubPendingSyncChanged(n)),
          ),
    );
    _subs.add(
      _notifications.watchNotifications(event.userId).listen(
            (n) => add(DashboardHubNotificationsReceived(n)),
          ),
    );

    final online = await _sync.isOnline();
    add(DashboardHubConnectivityChanged(isOnline: online));
  }

  void _onBills(DashboardHubBillsReceived e, Emitter<DashboardHubState> emit) {
    _gotBills = true;
    emit(state.copyWith(bills: e.bills));
    _requestRecompute();
    _maybeFinishInitialLoad(emit);
  }

  void _onProfile(
    DashboardHubProfileReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(profiles: e.profiles));
  }

  void _onProducts(
    DashboardHubProductsReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    _gotProducts = true;
    emit(state.copyWith(products: e.products));
    _requestRecompute();
    _maybeFinishInitialLoad(emit);
  }

  void _onExpenses(
    DashboardHubExpensesReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    _gotExpenses = true;
    emit(state.copyWith(expenses: e.expenses));
    _requestRecompute();
    _maybeFinishInitialLoad(emit);
  }

  void _onCustomers(
    DashboardHubCustomersReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    _gotCustomers = true;
    emit(state.copyWith(customers: e.customers));
    _requestRecompute();
    _maybeFinishInitialLoad(emit);
  }

  void _onPending(
    DashboardHubPendingSyncChanged e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(pendingSyncCount: e.count));
    _refreshAttentionOnly(emit);
  }

  void _onNotifications(
    DashboardHubNotificationsReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(notificationCount: e.notifications.length));
  }

  void _onConnectivity(
    DashboardHubConnectivityChanged e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(isOnline: e.isOnline));
    _refreshAttentionOnly(emit);
  }

  void _onAiUnread(
    DashboardHubAiUnreadChanged e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(aiUnreadCount: e.count));
    _refreshAttentionOnly(emit);
  }

  void _refreshAttentionOnly(Emitter<DashboardHubState> emit) {
    var attention = 0;
    if (state.partialBillsCount > 0) attention++;
    if (state.lowStockCount > 0) attention++;
    if (state.outOfStockCount > 0) attention++;
    if (state.pendingSyncCount > 0) attention++;
    if (!state.isOnline) attention++;
    if (state.aiUnreadCount > 0) attention++;
    if (attention == state.attentionItemCount) return;
    emit(state.copyWith(attentionItemCount: attention));
  }

  void _requestRecompute() {
    _debounce?.cancel();
    if (_pendingImmediateRecompute) {
      _pendingImmediateRecompute = false;
      if (!isClosed) add(const DashboardHubRecomputeRequested());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) add(const DashboardHubRecomputeRequested());
    });
  }

  Future<void> _onRecompute(
    DashboardHubRecomputeRequested event,
    Emitter<DashboardHubState> emit,
  ) async {
    final generation = ++_computeGeneration;
    final metrics = await compute(_computeDashboardMetrics, (
      bills: state.bills ?? [],
      products: state.products,
      expenses: state.expenses,
      customers: state.customers,
      pendingSyncCount: state.pendingSyncCount,
      isOnline: state.isOnline,
      aiUnreadCount: state.aiUnreadCount,
    ));

    if (isClosed || generation != _computeGeneration) return;

    _gotMetrics = true;
    emit(state.copyWith(
      revenueToday: metrics.revenueToday,
      revenueThisMonth: metrics.revenueThisMonth,
      billsToday: metrics.billsToday,
      lowStockCount: metrics.lowStockCount,
      monthExpenses: metrics.monthExpenses,
      netProfitThisMonth: metrics.netProfitThisMonth,
      totalCreditOutstanding: metrics.totalCreditOutstanding,
      topCreditCustomers: metrics.topCreditCustomers,
      lowStockProducts: metrics.lowStockProducts,
      billsThisMonth: metrics.billsThisMonth,
      avgBillValueToday: metrics.avgBillValueToday,
      revenueYesterday: metrics.revenueYesterday,
      revenueTodayVsYesterdayPercent: metrics.revenueTodayVsYesterdayPercent,
      partialBills: metrics.partialBills,
      partialBillsCount: metrics.partialBillsCount,
      pendingCollectionAmount: metrics.pendingCollectionAmount,
      outOfStockCount: metrics.outOfStockCount,
      inventoryRetailValue: metrics.inventoryRetailValue,
      activeCustomersThisMonth: metrics.activeCustomersThisMonth,
      profitMarginPercent: metrics.profitMarginPercent,
      monthPaymentMix: metrics.monthPaymentMix,
      topProductsThisMonth: metrics.topProductsThisMonth,
      attentionItemCount: metrics.attentionItemCount,
    ));
    _maybeFinishInitialLoad(emit);
  }

  Future<void> _cancelSubs() async {
    _debounce?.cancel();
    _computeGeneration++;
    _resetInitialLoadFlags();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _activeUserId = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubs();
    return super.close();
  }
}

typedef _MetricInputs = ({
  List<Bill> bills,
  List<Product> products,
  List<Expense> expenses,
  List<Customer> customers,
  int pendingSyncCount,
  bool isOnline,
  int aiUnreadCount,
});

typedef _MetricOutputs = ({
  double revenueToday,
  double revenueThisMonth,
  int billsToday,
  int lowStockCount,
  double monthExpenses,
  double netProfitThisMonth,
  double totalCreditOutstanding,
  List<Customer> topCreditCustomers,
  List<Product> lowStockProducts,
  int billsThisMonth,
  double avgBillValueToday,
  double revenueYesterday,
  double? revenueTodayVsYesterdayPercent,
  List<Bill> partialBills,
  int partialBillsCount,
  double pendingCollectionAmount,
  int outOfStockCount,
  double inventoryRetailValue,
  int activeCustomersThisMonth,
  double? profitMarginPercent,
  PaymentMixSnapshot monthPaymentMix,
  List<DashboardTopProduct> topProductsThisMonth,
  int attentionItemCount,
});

_MetricOutputs _computeDashboardMetrics(_MetricInputs input) {
  final bills = input.bills;
  final products = input.products;
  final expenses = input.expenses;
  final customers = input.customers;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  double revToday = 0;
  double revThisMonth = 0;
  double revYesterday = 0;
  int billsTodayCount = 0;
  int billsThisMonthCount = 0;
  final List<Bill> partials = [];

  for (final b in bills) {
    final amount = BillRevenue.recognizedAmount(b);
    if (BillRevenue.isSameCalendarDay(b, today)) {
      revToday += amount;
      billsTodayCount++;
    } else if (BillRevenue.isSameCalendarDay(b, yesterday)) {
      revYesterday += amount;
    }

    if (BillRevenue.isSameCalendarMonth(b, now)) {
      revThisMonth += amount;
      billsThisMonthCount++;
    }

    if (b.paymentStatus.toLowerCase().trim() == 'partial') {
      partials.add(b);
    }
  }

  double monthExp = 0;
  for (final e in expenses) {
    if (e.expenseDate.year == now.year && e.expenseDate.month == now.month) {
      monthExp += e.amount;
    }
  }

  final netProfit = revThisMonth - monthExp;
  final margin = revThisMonth > 0 ? (netProfit / revThisMonth) * 100 : null;

  final activeProducts = products.where((p) => p.isActive).toList();
  int lowStock = 0;
  int outStock = 0;
  double retailVal = 0;
  final List<Product> lowStockProds = [];

  for (final p in activeProducts) {
    retailVal += p.price * p.stockQuantity;
    if (p.stockQuantity <= 0) {
      outStock++;
      lowStockProds.add(p);
    } else if (p.isLowStock) {
      lowStock++;
      lowStockProds.add(p);
    }
  }

  double totalCredit = 0;
  for (final c in customers) {
    totalCredit += c.creditBalance;
  }
  final topCredit = [...customers]
    ..sort((a, b) => b.creditBalance.compareTo(a.creditBalance));

  final avgBillToday = billsTodayCount > 0 ? revToday / billsTodayCount : 0.0;
  final trend = revYesterday == 0 ? (revToday > 0 ? 100.0 : null) : ((revToday - revYesterday) / revYesterday) * 100;

  final pendingCol = partials.fold<double>(0, (s, b) => s + (b.totalAmount - b.paidAmount).clamp(0, double.infinity));

  // Payment Mix
  var complete = 0;
  var partial = 0;
  var pending = 0;
  for (final b in bills.where((x) => BillRevenue.isSameCalendarMonth(x, now))) {
    switch (b.paymentStatus.toLowerCase().trim()) {
      case 'complete': complete++;
      case 'partial': partial++;
      default: pending++;
    }
  }

  // Top Products
  final agg = <String, ({int units, double revenue})>{};
  for (final b in bills.where((x) => BillRevenue.isSameCalendarMonth(x, now))) {
    for (final line in b.lineItems) {
      final name = line.productName.trim();
      if (name.isEmpty) continue;
      final cur = agg[name];
      agg[name] = (
        units: (cur?.units ?? 0) + line.quantity,
        revenue: (cur?.revenue ?? 0) + line.totalPrice,
      );
    }
  }
  final topProds = agg.entries
      .map((e) => DashboardTopProduct(name: e.key, unitsSold: e.value.units, revenue: e.value.revenue))
      .toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  // Active Customers
  final custKeys = <String>{};
  for (final b in bills.where((x) => BillRevenue.isSameCalendarMonth(x, now))) {
    final phone = b.customerPhone.trim();
    final name = b.customerName.trim();
    if (phone.isNotEmpty) custKeys.add(phone);
    else if (name.isNotEmpty) custKeys.add(name.toLowerCase());
  }

  var attention = 0;
  if (partials.isNotEmpty) attention++;
  if (lowStock > 0) attention++;
  if (outStock > 0) attention++;
  if (input.pendingSyncCount > 0) attention++;
  if (!input.isOnline) attention++;
  if (input.aiUnreadCount > 0) attention++;

  return (
    revenueToday: revToday,
    revenueThisMonth: revThisMonth,
    billsToday: billsTodayCount,
    lowStockCount: lowStock,
    monthExpenses: monthExp,
    netProfitThisMonth: netProfit,
    totalCreditOutstanding: totalCredit,
    topCreditCustomers: topCredit.take(3).toList(),
    lowStockProducts: lowStockProds.take(8).toList(),
    billsThisMonth: billsThisMonthCount,
    avgBillValueToday: avgBillToday,
    revenueYesterday: revYesterday,
    revenueTodayVsYesterdayPercent: trend,
    partialBills: partials,
    partialBillsCount: partials.length,
    pendingCollectionAmount: pendingCol,
    outOfStockCount: outStock,
    inventoryRetailValue: retailVal,
    activeCustomersThisMonth: custKeys.length,
    profitMarginPercent: margin,
    monthPaymentMix: PaymentMixSnapshot(complete: complete, partial: partial, pending: pending),
    topProductsThisMonth: topProds,
    attentionItemCount: attention,
  );
}
