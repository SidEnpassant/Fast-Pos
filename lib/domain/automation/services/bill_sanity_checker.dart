import 'package:inventopos/domain/automation/entities/bill_sanity_result.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/bill.dart';

/// Pre-submit bill sanity checks (pure rules).
abstract final class BillSanityChecker {
  static BillSanityResult evaluate({
    required List<BillDraftLine> lines,
    required double draftTotal,
    required List<Bill> recentBills,
  }) {
    final warnings = <String>[];
    if (lines.isEmpty) {
      return const BillSanityResult(
          warnings: ['Bill has no lines'], blocked: true);
    }

    final last7 = recentBills
        .where((b) => b.createdAt.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            ))
        .toList();
    if (last7.isNotEmpty) {
      final avg = last7.map((b) => b.totalAmount).reduce((a, b) => a + b) /
          last7.length;
      if (avg > 0 && draftTotal > avg * 3) {
        warnings.add(
          'Total ₹${draftTotal.toStringAsFixed(0)} is over 3× your recent average (₹${avg.toStringAsFixed(0)})',
        );
      }
    }

    for (final line in lines) {
      if (line.quantity > 100) {
        warnings.add('Unusually high qty (${line.quantity}) for ${line.name}');
      }
    }

    return BillSanityResult(warnings: warnings);
  }
}
