import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_state.dart';

class CompleteTransactionsBloc
    extends Bloc<CompleteTransactionsEvent, CompleteTransactionsViewState> {
  CompleteTransactionsBloc(this._observeBills)
      : super(const CompleteTransactionsViewState()) {
    on<CompleteBillsReceived>(_onBillsReceived);
    on<CompleteSearchQueryChanged>(_onSearchQueryChanged);
    on<CompleteDateRangeChanged>(_onDateRangeChanged);
    on<CompleteSearchModeToggled>(_onSearchModeToggled);
    on<CompleteRecomputeRequested>(_onRecompute);

    _sub = _observeBills().listen(
      (bills) => add(CompleteBillsReceived(bills)),
    );
  }

  final ObserveBillsUseCase _observeBills;
  StreamSubscription<List<Bill>>? _sub;
  Timer? _debounce;

  void setSearchQuery(String q) => add(CompleteSearchQueryChanged(q));

  void setDateRange(DateTime? start, DateTime? end) =>
      add(CompleteDateRangeChanged(start, end));

  void toggleSearchMode() => add(const CompleteSearchModeToggled());

  void _onBillsReceived(
    CompleteBillsReceived event,
    Emitter<CompleteTransactionsViewState> emit,
  ) {
    emit(state.copyWith(bills: event.bills));
    _requestRecompute();
  }

  void _onSearchQueryChanged(
    CompleteSearchQueryChanged event,
    Emitter<CompleteTransactionsViewState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    _requestRecompute();
  }

  void _onDateRangeChanged(
    CompleteDateRangeChanged event,
    Emitter<CompleteTransactionsViewState> emit,
  ) {
    emit(state.copyWith(startDate: event.start, endDate: event.end));
    _requestRecompute();
  }

  void _onSearchModeToggled(
    CompleteSearchModeToggled event,
    Emitter<CompleteTransactionsViewState> emit,
  ) {
    final next = !state.isSearching;
    if (!next) {
      emit(state.copyWith(isSearching: false, searchQuery: ''));
    } else {
      emit(state.copyWith(isSearching: true));
    }
    _requestRecompute();
  }

  void _requestRecompute() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!isClosed) add(const CompleteRecomputeRequested());
    });
  }

  Future<void> _onRecompute(
    CompleteRecomputeRequested event,
    Emitter<CompleteTransactionsViewState> emit,
  ) async {
    final grouped = await compute(_groupTransactions, (
      bills: state.bills,
      query: state.searchQuery,
      start: state.startDate,
      end: state.endDate,
    ));

    emit(state.copyWith(
      groupedTransactions: grouped,
      loading: false,
    ));
  }

  static Map<String, List<Bill>> _groupTransactions(
      ({List<Bill> bills, String query, DateTime? start, DateTime? end}) arg) {
    final filtered = arg.bills.where((b) {
      if (b.paymentStatus != 'complete') return false;

      final matchesQuery = b.customerName.toLowerCase().contains(arg.query.toLowerCase());
      
      final isAfterStart = arg.start == null || b.createdAt.isAfter(arg.start!);
      final isBeforeEnd = arg.end == null || 
          b.createdAt.isBefore(arg.end!.add(const Duration(days: 1)));

      return matchesQuery && isAfterStart && isBeforeEnd;
    }).toList();

    final Map<String, List<Bill>> grouped = {};
    for (final bill in filtered) {
      final date = DateFormat('yyyy-MM-dd').format(bill.createdAt);
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(bill);
    }
    return grouped;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _sub?.cancel();
    return super.close();
  }
}
