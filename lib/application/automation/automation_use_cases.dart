import 'package:inventopos/domain/analytics/customer_analytics.dart';
import 'package:inventopos/domain/automation/entities/automation_job.dart';
import 'package:inventopos/domain/automation/entities/bill_sanity_result.dart';
import 'package:inventopos/domain/automation/entities/repeat_order_template.dart';
import 'package:inventopos/domain/automation/repositories/automation_job_port.dart';
import 'package:inventopos/domain/automation/services/bill_sanity_checker.dart';
import 'package:inventopos/domain/automation/services/credit_exposure_evaluator.dart';
import 'package:inventopos/domain/automation/services/dead_stock_evaluator.dart';
import 'package:inventopos/domain/automation/services/margin_leak_evaluator.dart';
import 'package:inventopos/domain/automation/services/repeat_order_analyzer.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

class BuildRepeatOrderTemplateUseCase {
  RepeatOrderTemplate call({
    required String customerId,
    required List<Bill> bills,
  }) {
    return RepeatOrderAnalyzer.analyze(customerId, bills);
  }
}

class EvaluateCreditExposureUseCase {
  List<CreditExposureAlert> call({
    required List<Bill> bills,
    required List<Customer> customers,
    double threshold = 5000,
  }) {
    final snapshot = CustomerAnalytics.compute(
      bills: bills,
      customers: customers,
    );
    return CreditExposureEvaluator.evaluate(snapshot, threshold: threshold);
  }
}

class BuildOpeningSnapshotUseCase {
  ({int partialCount, double pending, int lowStockCount}) call({
    required List<Bill> bills,
    required int reorderAlertCount,
  }) {
    final partial = bills.where((b) => b.paidAmount < b.totalAmount).toList();
    final pending = partial.fold<double>(
      0,
      (s, b) => s + (b.totalAmount - b.paidAmount),
    );
    return (
      partialCount: partial.length,
      pending: pending,
      lowStockCount: reorderAlertCount,
    );
  }
}

class BuildEodSummaryUseCase {
  ({int billCount, double revenue, double collected, double pending}) call(
    List<Bill> bills,
  ) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final todayBills =
        bills.where((b) => !b.createdAt.isBefore(start)).toList();
    final revenue = todayBills.fold<double>(0, (s, b) => s + b.totalAmount);
    final collected = todayBills.fold<double>(0, (s, b) => s + b.paidAmount);
    final pending = todayBills
        .where((b) => b.paidAmount < b.totalAmount)
        .fold<double>(0, (s, b) => s + (b.totalAmount - b.paidAmount));
    return (
      billCount: todayBills.length,
      revenue: revenue,
      collected: collected,
      pending: pending,
    );
  }
}

class EvaluateExpenseSpikeUseCase {
  bool call(List<Expense> expenses) {
    if (expenses.length < 4) return false;
    final sorted = [...expenses]
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    final recentWeek = sorted
        .where((e) => e.expenseDate.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            ))
        .fold<double>(0, (s, e) => s + e.amount);
    final prior = sorted.where((e) {
      final d = e.expenseDate;
      final now = DateTime.now();
      return d.isBefore(now.subtract(const Duration(days: 7))) &&
          d.isAfter(now.subtract(const Duration(days: 35)));
    }).fold<double>(0, (s, e) => s + e.amount);
    if (prior <= 0) return false;
    return recentWeek > prior * 1.5;
  }
}

class EvaluateDeadStockUseCase {
  EvaluateDeadStockUseCase(this._products);

  final ProductRepository _products;

  Future<List<DeadStockAlert>> call(String userId) async {
    final products = await _products.fetchProductsForUser(userId);
    return DeadStockEvaluator.evaluate(products);
  }
}

class EvaluateMarginLeaksUseCase {
  EvaluateMarginLeaksUseCase(this._products);

  final ProductRepository _products;

  Future<List<MarginLeakAlert>> call(String userId) async {
    final products = await _products.fetchProductsForUser(userId);
    return MarginLeakEvaluator.evaluate(products);
  }
}

class EvaluateBillSanityUseCase {
  BillSanityResult call({
    required List<BillDraftLine> lines,
    required double draftTotal,
    required List<Bill> recentBills,
  }) =>
      BillSanityChecker.evaluate(
        lines: lines,
        draftTotal: draftTotal,
        recentBills: recentBills,
      );
}

class ListAutomationJobsUseCase {
  ListAutomationJobsUseCase(this._jobs);

  final AutomationJobPort _jobs;

  Future<List<AutomationJob>> call(String userId) => _jobs.listForUser(userId);
}

class ToggleAutomationJobUseCase {
  ToggleAutomationJobUseCase(this._jobs);

  final AutomationJobPort _jobs;

  Future<void> call(String jobId, bool enabled) =>
      _jobs.toggleJob(jobId, enabled);
}
