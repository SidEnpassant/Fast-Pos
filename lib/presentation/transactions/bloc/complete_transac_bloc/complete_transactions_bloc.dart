import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
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
  int _computeGeneration = 0;
  bool _pendingImmediateRecompute = true;

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
    if (_pendingImmediateRecompute) {
      _pendingImmediateRecompute = false;
      if (!isClosed) add(const CompleteRecomputeRequested());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) add(const CompleteRecomputeRequested());
    });
  }

  Future<void> _onRecompute(
    CompleteRecomputeRequested event,
    Emitter<CompleteTransactionsViewState> emit,
  ) async {
    final generation = ++_computeGeneration;
    final input = (
      bills: state.bills,
      query: state.searchQuery,
      start: state.startDate,
      end: state.endDate,
    );
    final grouped = await compute(_groupTransactions, input);

    if (isClosed || generation != _computeGeneration) return;

    emit(state.copyWith(
      groupedTransactions: grouped,
      loading: false,
    ));
  }

  static Map<String, List<Bill>> _groupTransactions(
      ({List<Bill> bills, String query, DateTime? start, DateTime? end}) arg) {
    final filtered = arg.bills.where((b) {
      if (b.paymentStatus.toLowerCase().trim() != 'complete') return false;

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
    _computeGeneration++;
    _sub?.cancel();
    return super.close();
  }
}
