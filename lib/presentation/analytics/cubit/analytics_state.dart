import 'package:equatable/equatable.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.ready = false,
    this.rawBillRows = const [],
    this.monthlyRevenues = const {},
    this.monthlyTransactions = const {},
    this.sortedMonths = const [],
    this.selectedMonth,
    this.showChart = true,
  });

  final bool ready;
  final List<Map<String, dynamic>> rawBillRows;
  final Map<String, double> monthlyRevenues;
  final Map<String, int> monthlyTransactions;
  final List<String> sortedMonths;
  final String? selectedMonth;
  final bool showChart;

  bool get hasRevenueData => monthlyRevenues.isNotEmpty;

  AnalyticsState copyWith({
    bool? ready,
    List<Map<String, dynamic>>? rawBillRows,
    Map<String, double>? monthlyRevenues,
    Map<String, int>? monthlyTransactions,
    List<String>? sortedMonths,
    String? selectedMonth,
    bool? showChart,
  }) {
    return AnalyticsState(
      ready: ready ?? this.ready,
      rawBillRows: rawBillRows ?? this.rawBillRows,
      monthlyRevenues: monthlyRevenues ?? this.monthlyRevenues,
      monthlyTransactions: monthlyTransactions ?? this.monthlyTransactions,
      sortedMonths: sortedMonths ?? this.sortedMonths,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      showChart: showChart ?? this.showChart,
    );
  }

  @override
  List<Object?> get props => [
        ready,
        rawBillRows,
        monthlyRevenues,
        monthlyTransactions,
        sortedMonths,
        selectedMonth,
        showChart,
      ];
}
