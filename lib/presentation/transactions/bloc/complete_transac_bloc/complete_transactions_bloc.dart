import 'dart:async';

import 'package:bloc/bloc.dart';
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

    _sub = _observeBills().listen(
      (bills) => add(CompleteBillsReceived(bills)),
    );
  }

  final ObserveBillsUseCase _observeBills;
  StreamSubscription<List<Bill>>? _sub;

  void setSearchQuery(String q) => add(CompleteSearchQueryChanged(q));

  void setDateRange(DateTime? start, DateTime? end) =>
      add(CompleteDateRangeChanged(start, end));

  void toggleSearchMode() => add(const CompleteSearchModeToggled());

  void _onBillsReceived(
    CompleteBillsReceived event,
    Emitter<CompleteTransactionsViewState> emit,
  ) {
    emit(state.copyWith(bills: event.bills));
  }

  void _onSearchQueryChanged(
    CompleteSearchQueryChanged event,
    Emitter<CompleteTransactionsViewState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onDateRangeChanged(
    CompleteDateRangeChanged event,
    Emitter<CompleteTransactionsViewState> emit,
  ) {
    emit(state.copyWith(startDate: event.start, endDate: event.end));
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
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
