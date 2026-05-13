import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/presentation/analytics/cubit/analytics_state.dart';
import 'package:inventopos/supabase_mappers.dart';
import 'package:intl/intl.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit(this._billsRepository)
      : super(
          AnalyticsState(
            selectedMonth: DateFormat('MMM yyyy').format(DateTime.now()),
          ),
        ) {
    _sub = _billsRepository.watchBillsForCurrentUser().listen(_onRows);
  }

  final BillsRepository _billsRepository;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  void _onRows(List<Map<String, dynamic>> rows) {
    final monthlyRevenues = <String, double>{};
    final monthlyTransactions = <String, int>{};

    for (final row in rows) {
      try {
        final data = SupabaseMappers.billFromRow(row);
        final timestamp = data['createdAt'] as DateTime;
        final monthYear = DateFormat('MMM yyyy').format(timestamp);

        double amount = 0;
        if (data['paymentStatus'] == 'complete') {
          amount = (data['totalAmount'] ?? 0).toDouble();
        } else if (data['paymentStatus'] == 'partial') {
          amount = (data['paidAmount'] ?? 0).toDouble();
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
          rawBillRows: rows,
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
        rawBillRows: rows,
        monthlyRevenues: monthlyRevenues,
        monthlyTransactions: monthlyTransactions,
        sortedMonths: sortedMonths,
        selectedMonth: selected,
      ),
    );
  }

  void setSelectedMonth(String? month) {
    if (month == null) return;
    emit(state.copyWith(selectedMonth: month));
  }

  void toggleChartTable() {
    emit(state.copyWith(showChart: !state.showChart));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
