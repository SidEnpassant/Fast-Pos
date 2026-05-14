import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_event.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc(this._observeBills)
      : super(
          AnalyticsState(
            selectedMonth: DateFormat('MMM yyyy').format(DateTime.now()),
          ),
        ) {
    on<AnalyticsBillsReceived>(_onBillsReceived);
    on<AnalyticsMonthSelected>(_onMonthSelected);
    on<AnalyticsChartToggled>(_onChartToggled);

    _sub = _observeBills().listen(
      (bills) => add(AnalyticsBillsReceived(bills)),
    );
  }

  final ObserveBillsUseCase _observeBills;
  StreamSubscription<List<Bill>>? _sub;

  void setSelectedMonth(String? month) {
    if (month == null) return;
    add(AnalyticsMonthSelected(month));
  }

  void toggleChartTable() => add(const AnalyticsChartToggled());

  void _onBillsReceived(
    AnalyticsBillsReceived event,
    Emitter<AnalyticsState> emit,
  ) {
    final bills = event.bills;
    final monthlyRevenues = <String, double>{};
    final monthlyTransactions = <String, int>{};

    for (final bill in bills) {
      try {
        final monthYear = DateFormat('MMM yyyy').format(bill.createdAt);

        double amount = 0;
        if (bill.paymentStatus == 'complete') {
          amount = bill.totalAmount;
        } else if (bill.paymentStatus == 'partial') {
          amount = bill.paidAmount;
        }

        monthlyRevenues.update(
          monthYear,
          (value) => value + amount,
          ifAbsent: () => amount,
        );

        monthlyTransactions.update(
          monthYear,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      } catch (_) {
        continue;
      }
    }

    if (monthlyRevenues.isEmpty) {
      emit(
        state.copyWith(
          ready: true,
          bills: bills,
          monthlyRevenues: const {},
          monthlyTransactions: const {},
          sortedMonths: const [],
          selectedMonth: null,
        ),
      );
      return;
    }

    final sortedMonths = monthlyRevenues.keys.toList()
      ..sort(
        (a, b) => DateFormat('MMM yyyy')
            .parse(b)
            .compareTo(DateFormat('MMM yyyy').parse(a)),
      );

    var selected = state.selectedMonth;
    if (selected == null || !sortedMonths.contains(selected)) {
      selected = sortedMonths.first;
    }

    emit(
      state.copyWith(
        ready: true,
        bills: bills,
        monthlyRevenues: monthlyRevenues,
        monthlyTransactions: monthlyTransactions,
        sortedMonths: sortedMonths,
        selectedMonth: selected,
      ),
    );
  }

  void _onMonthSelected(
    AnalyticsMonthSelected event,
    Emitter<AnalyticsState> emit,
  ) {
    emit(state.copyWith(selectedMonth: event.month));
  }

  void _onChartToggled(
    AnalyticsChartToggled event,
    Emitter<AnalyticsState> emit,
  ) {
    emit(state.copyWith(showChart: !state.showChart));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
