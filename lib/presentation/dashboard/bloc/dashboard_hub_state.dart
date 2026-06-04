import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/entities/user_profile.dart';

/// Top product row for dashboard widgets.
class DashboardTopProduct {
  const DashboardTopProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });

  final String name;
  final int unitsSold;
  final double revenue;
}

class DashboardHubState extends Equatable {
  const DashboardHubState({
    this.profiles,
    this.bills,
    this.products = const [],
    this.expenses = const [],
    this.customers = const [],
    this.pendingSyncCount = 0,
    this.notificationCount = 0,
    this.aiUnreadCount = 0,
    this.isOnline = true,
    this.loading = true,
  });

  final List<UserProfile>? profiles;
  final List<Bill>? bills;
  final List<Product> products;
  final List<Expense> expenses;
  final List<Customer> customers;
  final int pendingSyncCount;
  final int notificationCount;
  final int aiUnreadCount;
  final bool isOnline;
  final bool loading;

  double get revenueToday {
    final bills = this.bills;
    if (bills == null) return 0;
    final today = DateTime.now();
    return bills
        .where((b) => BillRevenue.isSameCalendarDay(b, today))
        .fold(0.0, (sum, b) => sum + BillRevenue.recognizedAmount(b));
  }

  double get revenueThisMonth {
    final bills = this.bills;
    if (bills == null) return 0;
    final now = DateTime.now();
    return bills
        .where((b) => BillRevenue.isSameCalendarMonth(b, now))
        .fold(0.0, (sum, b) => sum + BillRevenue.recognizedAmount(b));
  }

  int get billsToday {
    final bills = this.bills;
    if (bills == null) return 0;
    final today = DateTime.now();
    return bills.where((b) => BillRevenue.isSameCalendarDay(b, today)).length;
  }

  int get lowStockCount => products.where((p) => p.isLowStock && p.isActive).length;

  double get monthExpenses {
    final now = DateTime.now();
    return expenses
        .where((e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get netProfitThisMonth => revenueThisMonth - monthExpenses;

  double get totalCreditOutstanding =>
      customers.fold(0.0, (s, c) => s + c.creditBalance);

  List<Customer> get topCreditCustomers {
    final withCredit = customers.where((c) => c.creditBalance > 0).toList()
      ..sort((a, b) => b.creditBalance.compareTo(a.creditBalance));
    return withCredit.take(3).toList();
  }

  List<Product> get lowStockProducts =>
      products.where((p) => p.isLowStock && p.isActive).take(8).toList();

  int get billsThisMonth {
    final bills = this.bills;
    if (bills == null) return 0;
    final now = DateTime.now();
    return bills.where((b) => BillRevenue.isSameCalendarMonth(b, now)).length;
  }

  double get avgBillValueToday =>
      billsToday > 0 ? revenueToday / billsToday : 0;

  double get revenueYesterday {
    final bills = this.bills;
    if (bills == null) return 0;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return bills
        .where((b) => BillRevenue.isSameCalendarDay(b, yesterday))
        .fold(0.0, (s, b) => s + BillRevenue.recognizedAmount(b));
  }

  double? get revenueTodayVsYesterdayPercent {
    final prev = revenueYesterday;
    final cur = revenueToday;
    if (prev == 0) return cur > 0 ? 100 : null;
    return ((cur - prev) / prev) * 100;
  }

  List<Bill> get partialBills =>
      bills
          ?.where((b) => b.paymentStatus.toLowerCase().trim() == 'partial')
          .toList() ??
      const [];

  int get partialBillsCount => partialBills.length;

  double get pendingCollectionAmount => partialBills.fold(
        0.0,
        (s, b) => s + (b.totalAmount - b.paidAmount).clamp(0, double.infinity),
      );

  int get outOfStockCount =>
      products.where((p) => p.isActive && p.stockQuantity <= 0).length;

  double get inventoryRetailValue => products
      .where((p) => p.isActive && p.deletedAt == null)
      .fold(0.0, (s, p) => s + p.price * p.stockQuantity);

  int get activeCustomersThisMonth {
    final bills = this.bills;
    if (bills == null) return 0;
    final now = DateTime.now();
    final keys = <String>{};
    for (final b in bills.where((x) => BillRevenue.isSameCalendarMonth(x, now))) {
      final phone = b.customerPhone.trim();
      final name = b.customerName.trim();
      if (phone.isNotEmpty) {
        keys.add(phone);
      } else if (name.isNotEmpty) {
        keys.add(name.toLowerCase());
      }
    }
    return keys.length;
  }

  double? get profitMarginPercent {
    if (revenueThisMonth <= 0) return null;
    return (netProfitThisMonth / revenueThisMonth) * 100;
  }

  PaymentMixSnapshot get monthPaymentMix {
    final bills = this.bills;
    if (bills == null) {
      return const PaymentMixSnapshot(complete: 0, partial: 0, pending: 0);
    }
    final now = DateTime.now();
    var complete = 0;
    var partial = 0;
    var pending = 0;
    for (final b in bills.where((x) => BillRevenue.isSameCalendarMonth(x, now))) {
      switch (b.paymentStatus.toLowerCase().trim()) {
        case 'complete':
          complete++;
        case 'partial':
          partial++;
        default:
          pending++;
      }
    }
    return PaymentMixSnapshot(
      complete: complete,
      partial: partial,
      pending: pending,
    );
  }

  List<DashboardTopProduct> get topProductsThisMonth {
    final bills = this.bills;
    if (bills == null) return const [];
    final now = DateTime.now();
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
    return agg.entries
        .map(
          (e) => DashboardTopProduct(
            name: e.key,
            unitsSold: e.value.units,
            revenue: e.value.revenue,
          ),
        )
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  int get attentionItemCount {
    var n = 0;
    if (partialBillsCount > 0) n++;
    if (lowStockCount > 0) n++;
    if (outOfStockCount > 0) n++;
    if (pendingSyncCount > 0) n++;
    if (!isOnline) n++;
    if (aiUnreadCount > 0) n++;
    return n;
  }

  DashboardHubState copyWith({
    List<UserProfile>? profiles,
    List<Bill>? bills,
    List<Product>? products,
    List<Expense>? expenses,
    List<Customer>? customers,
    int? pendingSyncCount,
    int? notificationCount,
    int? aiUnreadCount,
    bool? isOnline,
    bool? loading,
  }) {
    return DashboardHubState(
      profiles: profiles ?? this.profiles,
      bills: bills ?? this.bills,
      products: products ?? this.products,
      expenses: expenses ?? this.expenses,
      customers: customers ?? this.customers,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      notificationCount: notificationCount ?? this.notificationCount,
      aiUnreadCount: aiUnreadCount ?? this.aiUnreadCount,
      isOnline: isOnline ?? this.isOnline,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [
        profiles,
        bills,
        products,
        expenses,
        customers,
        pendingSyncCount,
        notificationCount,
        aiUnreadCount,
        isOnline,
        loading,
      ];
}
