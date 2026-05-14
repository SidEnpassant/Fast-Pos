import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.ready = false,
    this.bills = const [],
    this.monthlyRevenues = const {},
    this.monthlyTransactions = const {},
    this.sortedMonths = const [],
    this.selectedMonth,
    this.showChart = true,
  });

  final bool ready;
  final List<Bill> bills;
  final Map<String, double> monthlyRevenues;
  final Map<String, int> monthlyTransactions;
  final List<String> sortedMonths;
  final String? selectedMonth;
  final bool showChart;

  bool get hasRevenueData => monthlyRevenues.isNotEmpty;

  AnalyticsState copyWith({
    bool? ready,
    List<Bill>? bills,
    Map<String, double>? monthlyRevenues,
    Map<String, int>? monthlyTransactions,
    List<String>? sortedMonths,
    String? selectedMonth,
    bool? showChart,
  }) {
    return AnalyticsState(
      ready: ready ?? this.ready,
      bills: bills ?? this.bills,
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
        bills,
        monthlyRevenues,
        monthlyTransactions,
        sortedMonths,
        selectedMonth,
        showChart,
      ];
}
