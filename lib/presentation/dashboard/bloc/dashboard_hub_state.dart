import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/entities/user_profile.dart';

class DashboardHubState extends Equatable {
  const DashboardHubState({
    this.profiles,
    this.bills,
    this.products = const [],
    this.expenses = const [],
    this.customers = const [],
    this.pendingSyncCount = 0,
    this.notificationCount = 0,
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
  final bool isOnline;
  final bool loading;

  double get revenueToday {
    final bills = this.bills;
    if (bills == null) return 0;
    final today = DateTime.now();
    return bills.where((b) => _isSameDay(b.createdAt, today)).fold(0.0, _billRevenue);
  }

  double get revenueThisMonth {
    final bills = this.bills;
    if (bills == null) return 0;
    final now = DateTime.now();
    return bills
        .where((b) => b.createdAt.year == now.year && b.createdAt.month == now.month)
        .fold(0.0, _billRevenue);
  }

  int get billsToday {
    final bills = this.bills;
    if (bills == null) return 0;
    final today = DateTime.now();
    return bills.where((b) => _isSameDay(b.createdAt, today)).length;
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

  DashboardHubState copyWith({
    List<UserProfile>? profiles,
    List<Bill>? bills,
    List<Product>? products,
    List<Expense>? expenses,
    List<Customer>? customers,
    int? pendingSyncCount,
    int? notificationCount,
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
      isOnline: isOnline ?? this.isOnline,
      loading: loading ?? this.loading,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static double _billRevenue(double sum, Bill b) {
    if (b.paymentStatus == 'complete') return sum + b.totalAmount;
    if (b.paymentStatus == 'partial') return sum + b.paidAmount;
    return sum;
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
        isOnline,
        loading,
      ];
}
