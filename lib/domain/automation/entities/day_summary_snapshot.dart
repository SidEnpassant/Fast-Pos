import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

class DaySummarySnapshot extends Equatable {
  const DaySummarySnapshot({
    required this.billCount,
    required this.revenue,
    required this.collected,
    required this.pending,
    required this.partialBillCount,
    required this.lowStockCount,
  });

  final int billCount;
  final double revenue;
  final double collected;
  final double pending;
  final int partialBillCount;
  final int lowStockCount;

  @override
  List<Object?> get props => [
        billCount,
        revenue,
        collected,
        pending,
        partialBillCount,
        lowStockCount,
      ];
}

abstract final class PeakHoursAnalyzer {
  static Map<int, int> hourCounts(List<Bill> bills) {
    final counts = <int, int>{};
    for (final b in bills) {
      final h = b.createdAt.hour;
      counts[h] = (counts[h] ?? 0) + 1;
    }
    return counts;
  }

  static int? busiestHour(List<Bill> bills) {
    final counts = hourCounts(bills);
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
