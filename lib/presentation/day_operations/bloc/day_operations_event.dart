import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

sealed class DayOperationsEvent extends Equatable {
  const DayOperationsEvent();
  @override
  List<Object?> get props => [];
}

final class DayOperationsStarted extends DayOperationsEvent {
  const DayOperationsStarted({
    required this.bills,
    required this.reorderAlertCount,
    required this.expenses,
  });
  final List<Bill> bills;
  final int reorderAlertCount;
  final List<dynamic> expenses;
  @override
  List<Object?> get props => [bills, reorderAlertCount];
}

final class DayOperationsSnapshotComputed extends DayOperationsEvent {
  const DayOperationsSnapshotComputed({
    required this.partialCount,
    required this.pending,
    required this.lowStockCount,
    required this.billCount,
    required this.revenue,
    required this.collected,
    required this.eodPending,
    required this.expenseSpike,
  });
  final int partialCount;
  final double pending;
  final int lowStockCount;
  final int billCount;
  final double revenue;
  final double collected;
  final double eodPending;
  final bool expenseSpike;
  @override
  List<Object?> get props =>
      [partialCount, pending, lowStockCount, billCount, revenue];
}
