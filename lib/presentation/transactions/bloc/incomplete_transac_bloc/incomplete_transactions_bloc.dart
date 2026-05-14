import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/billing/sync_overdue_partial_bill_notifications_use_case.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/transactions/bloc/incomplete_transac_bloc/incomplete_transactions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/incomplete_transac_bloc/incomplete_transactions_state.dart';

class IncompleteTransactionsBloc extends Bloc<IncompleteTransactionsEvent,
    IncompleteTransactionsViewState> {
  IncompleteTransactionsBloc(
    this._observeBills,
    this._syncOverdue,
    this._authRepository,
  ) : super(const IncompleteTransactionsViewState()) {
    on<IncompleteBillsReceived>(_onBillsReceived);
    on<IncompleteSearchQueryChanged>(_onSearchQueryChanged);
    on<IncompleteSelectedDateChanged>(_onSelectedDateChanged);
    on<IncompleteSearchModeToggled>(_onSearchModeToggled);

    _sub = _observeBills().listen(
      (bills) => add(IncompleteBillsReceived(bills)),
    );
  }

  final ObserveBillsUseCase _observeBills;
  final SyncOverduePartialBillNotificationsUseCase _syncOverdue;
  final AuthRepository _authRepository;
  StreamSubscription<List<Bill>>? _sub;
  bool _overdueSyncStarted = false;

  void setSearchQuery(String q) =>
      add(IncompleteSearchQueryChanged(q.toLowerCase()));

  void setSelectedDate(DateTime? d) =>
      add(IncompleteSelectedDateChanged(d));

  void toggleSearchMode() => add(const IncompleteSearchModeToggled());

  Future<void> _onBillsReceived(
    IncompleteBillsReceived event,
    Emitter<IncompleteTransactionsViewState> emit,
  ) async {
    emit(state.copyWith(bills: event.bills));
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
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
