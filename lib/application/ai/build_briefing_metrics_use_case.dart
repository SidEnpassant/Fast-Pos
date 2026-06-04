import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';

/// Builds a PII-minimal metrics snapshot for [ai-briefing].
class BuildBriefingMetricsUseCase {
  Map<String, dynamic> call({
    required List<Bill> bills,
    required List<Expense> expenses,
    required List<Product> products,
  }) {
    final now = DateTime.now();
    final snapshot = BusinessAnalytics.compute(
      bills: bills,
      expenses: expenses,
      products: products,
      reference: now,
    );
    final partialCount =
        bills.where((b) => b.paymentStatus == 'partial').length;
    final revenueToday = bills
        .where((b) => BillRevenue.isSameCalendarDay(b, now))
        .fold(0.0, (s, b) => s + BillRevenue.recognizedAmount(b));

    return {
      'revenue_today': revenueToday,
      'revenue_month': snapshot.revenueTrend.current,
      'bills_month': snapshot.billsTrend.current,
      'expenses_month': snapshot.expensesTrend.current,
      'profit_month': snapshot.profitTrend.current,
      'partial_bills': partialCount,
      'low_stock_count': products.where((p) => p.isActive && p.isLowStock).length,
      'out_of_stock_count':
          products.where((p) => p.isActive && p.stockQuantity <= 0).length,
    };
  }
}
