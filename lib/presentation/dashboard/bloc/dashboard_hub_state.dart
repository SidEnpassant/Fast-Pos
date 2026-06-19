import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
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
  final double unitsSold;
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
    this.revenueToday = 0,
    this.revenueThisMonth = 0,
    this.billsToday = 0,
    this.lowStockCount = 0,
    this.monthExpenses = 0,
    this.netProfitThisMonth = 0,
    this.totalCreditOutstanding = 0,
    this.topCreditCustomers = const [],
    this.lowStockProducts = const [],
    this.billsThisMonth = 0,
    this.avgBillValueToday = 0,
    this.revenueYesterday = 0,
    this.revenueTodayVsYesterdayPercent,
    this.partialBills = const [],
    this.partialBillsCount = 0,
    this.pendingCollectionAmount = 0,
    this.outOfStockCount = 0,
    this.inventoryRetailValue = 0,
    this.activeCustomersThisMonth = 0,
    this.profitMarginPercent,
    this.monthPaymentMix =
        const PaymentMixSnapshot(complete: 0, partial: 0, pending: 0),
    this.topProductsThisMonth = const [],
    this.attentionItemCount = 0,
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

  final double revenueToday;
  final double revenueThisMonth;
  final int billsToday;
  final int lowStockCount;
  final double monthExpenses;
  final double netProfitThisMonth;
  final double totalCreditOutstanding;
  final List<Customer> topCreditCustomers;
  final List<Product> lowStockProducts;
  final int billsThisMonth;
  final double avgBillValueToday;
  final double revenueYesterday;
  final double? revenueTodayVsYesterdayPercent;
  final List<Bill> partialBills;
  final int partialBillsCount;
  final double pendingCollectionAmount;
  final int outOfStockCount;
  final double inventoryRetailValue;
  final int activeCustomersThisMonth;
  final double? profitMarginPercent;
  final PaymentMixSnapshot monthPaymentMix;
  final List<DashboardTopProduct> topProductsThisMonth;
  final int attentionItemCount;

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
    double? revenueToday,
    double? revenueThisMonth,
    int? billsToday,
    int? lowStockCount,
    double? monthExpenses,
    double? netProfitThisMonth,
    double? totalCreditOutstanding,
    List<Customer>? topCreditCustomers,
    List<Product>? lowStockProducts,
    int? billsThisMonth,
    double? avgBillValueToday,
    double? revenueYesterday,
    double? revenueTodayVsYesterdayPercent,
    List<Bill>? partialBills,
    int? partialBillsCount,
    double? pendingCollectionAmount,
    int? outOfStockCount,
    double? inventoryRetailValue,
    int? activeCustomersThisMonth,
    double? profitMarginPercent,
    PaymentMixSnapshot? monthPaymentMix,
    List<DashboardTopProduct>? topProductsThisMonth,
    int? attentionItemCount,
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
      revenueToday: revenueToday ?? this.revenueToday,
      revenueThisMonth: revenueThisMonth ?? this.revenueThisMonth,
      billsToday: billsToday ?? this.billsToday,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      monthExpenses: monthExpenses ?? this.monthExpenses,
      netProfitThisMonth: netProfitThisMonth ?? this.netProfitThisMonth,
      totalCreditOutstanding:
          totalCreditOutstanding ?? this.totalCreditOutstanding,
      topCreditCustomers: topCreditCustomers ?? this.topCreditCustomers,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      billsThisMonth: billsThisMonth ?? this.billsThisMonth,
      avgBillValueToday: avgBillValueToday ?? this.avgBillValueToday,
      revenueYesterday: revenueYesterday ?? this.revenueYesterday,
      revenueTodayVsYesterdayPercent:
          revenueTodayVsYesterdayPercent ?? this.revenueTodayVsYesterdayPercent,
      partialBills: partialBills ?? this.partialBills,
      partialBillsCount: partialBillsCount ?? this.partialBillsCount,
      pendingCollectionAmount:
          pendingCollectionAmount ?? this.pendingCollectionAmount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
      inventoryRetailValue: inventoryRetailValue ?? this.inventoryRetailValue,
      activeCustomersThisMonth:
          activeCustomersThisMonth ?? this.activeCustomersThisMonth,
      profitMarginPercent: profitMarginPercent ?? this.profitMarginPercent,
      monthPaymentMix: monthPaymentMix ?? this.monthPaymentMix,
      topProductsThisMonth: topProductsThisMonth ?? this.topProductsThisMonth,
      attentionItemCount: attentionItemCount ?? this.attentionItemCount,
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
        revenueToday,
        revenueThisMonth,
        billsToday,
        lowStockCount,
        monthExpenses,
        netProfitThisMonth,
        totalCreditOutstanding,
        topCreditCustomers,
        lowStockProducts,
        billsThisMonth,
        avgBillValueToday,
        revenueYesterday,
        revenueTodayVsYesterdayPercent,
        partialBills,
        partialBillsCount,
        pendingCollectionAmount,
        outOfStockCount,
        inventoryRetailValue,
        activeCustomersThisMonth,
        profitMarginPercent,
        monthPaymentMix,
        topProductsThisMonth,
        attentionItemCount,
      ];
}
