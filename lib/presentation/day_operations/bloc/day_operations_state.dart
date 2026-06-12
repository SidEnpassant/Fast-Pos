import 'package:equatable/equatable.dart';

class DayOperationsState extends Equatable {
  const DayOperationsState({
    this.partialCount = 0,
    this.pending = 0,
    this.lowStockCount = 0,
    this.billCount = 0,
    this.revenue = 0,
    this.collected = 0,
    this.eodPending = 0,
    this.expenseSpike = false,
    this.loading = false,
  });

  final int partialCount;
  final double pending;
  final int lowStockCount;
  final int billCount;
  final double revenue;
  final double collected;
  final double eodPending;
  final bool expenseSpike;
  final bool loading;

  DayOperationsState copyWith({
    int? partialCount,
    double? pending,
    int? lowStockCount,
    int? billCount,
    double? revenue,
    double? collected,
    double? eodPending,
    bool? expenseSpike,
    bool? loading,
  }) =>
      DayOperationsState(
        partialCount: partialCount ?? this.partialCount,
        pending: pending ?? this.pending,
        lowStockCount: lowStockCount ?? this.lowStockCount,
        billCount: billCount ?? this.billCount,
        revenue: revenue ?? this.revenue,
        collected: collected ?? this.collected,
        eodPending: eodPending ?? this.eodPending,
        expenseSpike: expenseSpike ?? this.expenseSpike,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props =>
      [partialCount, pending, lowStockCount, billCount, revenue, expenseSpike, loading];
}
