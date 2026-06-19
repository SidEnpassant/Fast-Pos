import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/billing/sync_overdue_partial_bill_notifications_use_case.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/transactions/bloc/incomplete_transac_bloc/incomplete_transactions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/incomplete_transac_bloc/incomplete_transactions_state.dart';

class IncompleteTransactionsBloc
    extends Bloc<IncompleteTransactionsEvent, IncompleteTransactionsViewState> {
  IncompleteTransactionsBloc(
    this._observeBills,
    this._syncOverdue,
    this._authRepository,
  ) : super(const IncompleteTransactionsViewState()) {
    on<IncompleteBillsReceived>(_onBillsReceived);
    on<IncompleteSearchQueryChanged>(_onSearchQueryChanged);
    on<IncompleteSelectedDateChanged>(_onSelectedDateChanged);
    on<IncompleteSearchModeToggled>(_onSearchModeToggled);
    on<IncompleteRecomputeRequested>(_onRecompute);

    _sub = _observeBills().listen(
      (bills) => add(IncompleteBillsReceived(bills)),
    );
  }

  final ObserveBillsUseCase _observeBills;
  final SyncOverduePartialBillNotificationsUseCase _syncOverdue;
  final AuthRepository _authRepository;
  StreamSubscription<List<Bill>>? _sub;
  Timer? _debounce;
  int _computeGeneration = 0;
  bool _overdueSyncStarted = false;
  bool _pendingImmediateRecompute = true;

  void setSearchQuery(String q) =>
      add(IncompleteSearchQueryChanged(q.toLowerCase()));

  void setSelectedDate(DateTime? d) => add(IncompleteSelectedDateChanged(d));

  void toggleSearchMode() => add(const IncompleteSearchModeToggled());

  Future<void> _onBillsReceived(
    IncompleteBillsReceived event,
    Emitter<IncompleteTransactionsViewState> emit,
  ) async {
    emit(state.copyWith(bills: event.bills));
    _requestRecompute();

    if (_overdueSyncStarted) return;
    final uid = _authRepository.currentSession?.userId;
    if (uid == null) return;
    _overdueSyncStarted = true;
    try {
      await _syncOverdue(userId: uid);
    } catch (_) {}
  }

  void _onSearchQueryChanged(
    IncompleteSearchQueryChanged event,
    Emitter<IncompleteTransactionsViewState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    _requestRecompute();
  }

  void _onSelectedDateChanged(
    IncompleteSelectedDateChanged event,
    Emitter<IncompleteTransactionsViewState> emit,
  ) {
    emit(
      state.copyWith(
        selectedDate: event.date,
        clearSelectedDate: event.date == null,
      ),
    );
    _requestRecompute();
  }

  void _onSearchModeToggled(
    IncompleteSearchModeToggled event,
    Emitter<IncompleteTransactionsViewState> emit,
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
      if (!isClosed) add(const IncompleteRecomputeRequested());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) add(const IncompleteRecomputeRequested());
    });
  }

  Future<void> _onRecompute(
    IncompleteRecomputeRequested event,
    Emitter<IncompleteTransactionsViewState> emit,
  ) async {
    final generation = ++_computeGeneration;
    final input = (
      bills: state.bills,
      query: state.searchQuery,
      selectedDate: state.selectedDate,
    );
    final grouped = await compute(_groupPartialTransactions, input);

    if (isClosed || generation != _computeGeneration) return;

    emit(state.copyWith(
      groupedTransactions: grouped,
      loading: false,
    ));
  }

  static Map<String, List<Bill>> _groupPartialTransactions(
    ({
      List<Bill> bills,
      String query,
      DateTime? selectedDate,
    }) arg,
  ) {
    final partialRows = arg.bills
        .where((b) => b.paymentStatus.toLowerCase().trim() == 'partial')
        .toList();

    final filtered = partialRows.where((bill) {
      if (!bill.customerName.toLowerCase().contains(arg.query)) {
        return false;
      }
      if (arg.selectedDate == null) return true;
      return DateFormat('yyyy-MM-dd').format(bill.createdAt) ==
          DateFormat('yyyy-MM-dd').format(arg.selectedDate!);
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
