import 'package:intl/intl.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';

/// Month-over-month change for a metric.
class MonthTrend {
  const MonthTrend({required this.current, required this.previous});

  final double current;
  final double previous;

  double get delta => current - previous;

  double? get changePercent {
    if (previous == 0) return current > 0 ? 100 : null;
    return ((current - previous) / previous) * 100;
  }
}

class PaymentMixSnapshot {
  const PaymentMixSnapshot({
    required this.complete,
    required this.partial,
    required this.pending,
  });

  final int complete;
  final int partial;
  final int pending;

  int get total => complete + partial + pending;
}

class RecentBillRow {
  const RecentBillRow({
    required this.id,
    required this.label,
    required this.customerName,
    required this.amount,
    required this.paymentStatus,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String customerName;
  final double amount;
  final String paymentStatus;
  final DateTime createdAt;
}

class TopProductRow {
  const TopProductRow({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });

  final String name;
  final int unitsSold;
  final double revenue;
}

class ExpenseCategoryRow {
  const ExpenseCategoryRow({
    required this.category,
    required this.amount,
    required this.sharePercent,
  });

  final String category;
  final double amount;
  final double sharePercent;
}

class InventoryProductRow {
  const InventoryProductRow({
    required this.id,
    required this.name,
    required this.stockQuantity,
    required this.minStockThreshold,
    required this.price,
    required this.isOutOfStock,
  });

  final String id;
  final String name;
  final int stockQuantity;
  final int minStockThreshold;
  final double price;
  final bool isOutOfStock;

  double get fillRatio {
    if (minStockThreshold <= 0) return stockQuantity > 0 ? 1 : 0;
    return (stockQuantity / minStockThreshold).clamp(0.0, 1.5) / 1.5;
  }
}

class InventoryInsightsSnapshot {
  const InventoryInsightsSnapshot({
    required this.totalSkus,
    required this.outOfStock,
    required this.lowStock,
    required this.inStock,
    required this.retailValue,
    required this.costValue,
    required this.lowStockItems,
  });

  final int totalSkus;
  final int outOfStock;
  final int lowStock;
  final int inStock;
  final double retailValue;
  final double costValue;
  final List<InventoryProductRow> lowStockItems;

  static const empty = InventoryInsightsSnapshot(
    totalSkus: 0,
    outOfStock: 0,
    lowStock: 0,
    inStock: 0,
    retailValue: 0,
    costValue: 0,
    lowStockItems: [],
  );
}

class BusinessAnalyticsSnapshot {
  const BusinessAnalyticsSnapshot({
    required this.revenueTrend,
    required this.billsTrend,
    required this.expensesTrend,
    required this.profitTrend,
    required this.avgBillValueThisMonth,
    required this.paymentMix,
    required this.recentBills,
    required this.topProductsThisMonth,
    required this.expenseBreakdownThisMonth,
    required this.inventory,
  });

  final MonthTrend revenueTrend;
  final MonthTrend billsTrend;
  final MonthTrend expensesTrend;
  final MonthTrend profitTrend;
  final double avgBillValueThisMonth;
  final PaymentMixSnapshot paymentMix;
  final List<RecentBillRow> recentBills;
  final List<TopProductRow> topProductsThisMonth;
  final List<ExpenseCategoryRow> expenseBreakdownThisMonth;
  final InventoryInsightsSnapshot inventory;

  static const empty = BusinessAnalyticsSnapshot(
    revenueTrend: MonthTrend(current: 0, previous: 0),
    billsTrend: MonthTrend(current: 0, previous: 0),
    expensesTrend: MonthTrend(current: 0, previous: 0),
    profitTrend: MonthTrend(current: 0, previous: 0),
    avgBillValueThisMonth: 0,
    paymentMix: PaymentMixSnapshot(complete: 0, partial: 0, pending: 0),
    recentBills: [],
    topProductsThisMonth: [],
    expenseBreakdownThisMonth: [],
    inventory: InventoryInsightsSnapshot.empty,
  );
}

abstract final class BusinessAnalytics {
  static String monthKey(DateTime dt) =>
      DateFormat('MMM yyyy').format(dt.toLocal());

  static DateTime _monthStart(DateTime ref) =>
      DateTime(ref.year, ref.month, 1);

  static DateTime _previousMonth(DateTime ref) {
    final start = _monthStart(ref);
    return DateTime(start.year, start.month - 1, 1);
  }

  static double revenueForMonth(List<Bill> bills, DateTime monthRef) {
    return bills
        .where((b) => BillRevenue.isSameCalendarMonth(b, monthRef))
        .fold(0.0, (s, b) => s + BillRevenue.recognizedAmount(b));
  }

  static int billsCountForMonth(List<Bill> bills, DateTime monthRef) {
    return bills
        .where((b) => BillRevenue.isSameCalendarMonth(b, monthRef))
        .length;
  }

  static double expensesForMonth(List<Expense> expenses, DateTime monthRef) {
    return expenses
        .where((e) =>
            e.expenseDate.year == monthRef.year &&
            e.expenseDate.month == monthRef.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  static List<String> trailingMonthKeys(DateTime ref, {int count = 6}) {
    final start = _monthStart(ref);
    return List.generate(count, (i) {
      final d = DateTime(start.year, start.month - (count - 1 - i), 1);
      return monthKey(d);
    });
  }

  static Map<String, double> monthlyRevenueMap(List<Bill> bills) {
    final map = <String, double>{};
    for (final bill in bills) {
      final key = monthKey(BillRevenue.localCreatedDate(bill));
      map.update(
        key,
        (v) => v + BillRevenue.recognizedAmount(bill),
        ifAbsent: () => BillRevenue.recognizedAmount(bill),
      );
    }
    return map;
  }

  static Map<String, int> monthlyTransactionMap(List<Bill> bills) {
    final map = <String, int>{};
    for (final bill in bills) {
      final key = monthKey(BillRevenue.localCreatedDate(bill));
      map.update(key, (v) => v + 1, ifAbsent: () => 1);
    }
    return map;
  }

  static DateTime? parseMonthKey(String? key) {
    if (key == null || key.isEmpty) return null;
    try {
      return DateFormat('MMM yyyy').parse(key);
    } catch (_) {
      return null;
    }
  }

  static List<ExpenseCategoryRow> expenseBreakdownForMonth(
    List<Expense> expenses,
    DateTime monthRef,
  ) {
    final monthExpenses = expenses.where(
      (e) =>
          e.expenseDate.year == monthRef.year &&
          e.expenseDate.month == monthRef.month,
    );
    final byCategory = <String, double>{};
    for (final e in monthExpenses) {
      final cat =
          e.category.trim().isEmpty ? 'Uncategorized' : e.category.trim();
      byCategory.update(cat, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final totalExp =
        byCategory.values.fold<double>(0, (s, v) => s + v);
    return byCategory.entries
        .map(
          (e) => ExpenseCategoryRow(
            category: e.key,
            amount: e.value,
            sharePercent: totalExp > 0 ? (e.value / totalExp) * 100 : 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static BusinessAnalyticsSnapshot compute({
    required List<Bill> bills,
    required List<Expense> expenses,
    required List<Product> products,
    DateTime? reference,
  }) {
    final now = (reference ?? DateTime.now()).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final prevMonth = _previousMonth(now);

    double revenueNow = 0;
    double revenuePrev = 0;
    int billsNow = 0;
    int billsPrev = 0;
    
    final List<Bill> monthBills = [];
    final List<Bill> sortedBills = List<Bill>.from(bills)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final b in bills) {
      final amount = BillRevenue.recognizedAmount(b);
      if (BillRevenue.isSameCalendarMonth(b, now)) {
        revenueNow += amount;
        billsNow++;
        monthBills.add(b);
      } else if (BillRevenue.isSameCalendarMonth(b, prevMonth)) {
        revenuePrev += amount;
        billsPrev++;
      }
    }

    double expNow = 0;
    double expPrev = 0;
    final Map<String, double> categoriesNow = {};

    for (final e in expenses) {
      if (e.expenseDate.year == now.year && e.expenseDate.month == now.month) {
        expNow += e.amount;
        final cat = e.category.trim().isEmpty ? 'Uncategorized' : e.category.trim();
        categoriesNow.update(cat, (v) => v + e.amount, ifAbsent: () => e.amount);
      } else if (e.expenseDate.year == prevMonth.year && e.expenseDate.month == prevMonth.month) {
        expPrev += e.amount;
      }
    }

    final profitNow = revenueNow - expNow;
    final profitPrev = revenuePrev - expPrev;
    final avgBill = billsNow > 0 ? revenueNow / billsNow : 0.0;

    var complete = 0, partial = 0, pending = 0;
    final productAgg = <String, ({int units, double revenue})>{};

    for (final b in monthBills) {
      switch (b.paymentStatus.toLowerCase().trim()) {
        case 'complete': complete++; break;
        case 'partial': partial++; break;
        default: pending++; break;
      }
      for (final line in b.lineItems) {
        final name = line.productName.trim();
        if (name.isEmpty) continue;
        final cur = productAgg[name];
        productAgg[name] = (
          units: (cur?.units ?? 0) + line.quantity,
          revenue: (cur?.revenue ?? 0) + line.totalPrice,
        );
      }
    }

    final recentRows = sortedBills.take(6).map((b) {
      final num = b.displayBillNumber?.trim();
      return RecentBillRow(
        id: b.id,
        label: (num != null && num.isNotEmpty) ? '#$num' : 'Bill',
        customerName: b.customerName.trim().isEmpty ? 'Walk-in' : b.customerName,
        amount: BillRevenue.recognizedAmount(b),
        paymentStatus: b.paymentStatus,
        createdAt: BillRevenue.localCreatedDate(b),
      );
    }).toList();

    final topProducts = productAgg.entries
        .map((e) => TopProductRow(name: e.key, unitsSold: e.value.units, revenue: e.value.revenue))
        .toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

    final breakdown = categoriesNow.entries
        .map((e) => ExpenseCategoryRow(
            category: e.key,
            amount: e.value,
            sharePercent: expNow > 0 ? (e.value / expNow) * 100 : 0))
        .toList()..sort((a, b) => b.amount.compareTo(a.amount));

    final activeProducts = products.where((p) => p.isActive && p.deletedAt == null);
    int out = 0, low = 0, healthy = 0;
    double retail = 0, cost = 0;
    final List<InventoryProductRow> lowItems = [];

    for (final p in activeProducts) {
      retail += p.price * p.stockQuantity;
      if (p.costPrice != null) cost += p.costPrice! * p.stockQuantity;
      
      if (p.stockQuantity <= 0) {
        out++;
        lowItems.add(InventoryProductRow(
          id: p.id, name: p.name, stockQuantity: p.stockQuantity,
          minStockThreshold: p.minStockThreshold, price: p.price, isOutOfStock: true,
        ));
      } else if (p.isLowStock) {
        low++;
        lowItems.add(InventoryProductRow(
          id: p.id, name: p.name, stockQuantity: p.stockQuantity,
          minStockThreshold: p.minStockThreshold, price: p.price, isOutOfStock: false,
        ));
      } else {
        healthy++;
      }
    }

    lowItems.sort((a, b) {
      if (a.isOutOfStock != b.isOutOfStock) return a.isOutOfStock ? -1 : 1;
      return a.stockQuantity.compareTo(b.stockQuantity);
    });

    return BusinessAnalyticsSnapshot(
      revenueTrend: MonthTrend(current: revenueNow, previous: revenuePrev),
      billsTrend: MonthTrend(current: billsNow.toDouble(), previous: billsPrev.toDouble()),
      expensesTrend: MonthTrend(current: expNow, previous: expPrev),
      profitTrend: MonthTrend(current: profitNow, previous: profitPrev),
      avgBillValueThisMonth: avgBill,
      paymentMix: PaymentMixSnapshot(complete: complete, partial: partial, pending: pending),
      recentBills: recentRows,
      topProductsThisMonth: topProducts.take(8).toList(),
      expenseBreakdownThisMonth: breakdown,
      inventory: InventoryInsightsSnapshot(
        totalSkus: out + low + healthy,
        outOfStock: out, lowStock: low, inStock: healthy,
        retailValue: retail, costValue: cost,
        lowStockItems: lowItems.take(20).toList(),
      ),
    );
  }
}
