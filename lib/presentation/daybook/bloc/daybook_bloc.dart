import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/daybook/compute_day_book_use_case.dart';
import 'package:inventopos/application/daybook/record_cash_entry_use_case.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';

part 'daybook_event.dart';
part 'daybook_state.dart';

class DayBookBloc extends Bloc<DayBookEvent, DayBookState> {
  DayBookBloc({
    required ComputeDayBookUseCase computeDayBook,
    required RecordCashEntryUseCase recordCashEntry,
    required AuthRepository auth,
  })  : _computeDayBook = computeDayBook,
        _recordCashEntry = recordCashEntry,
        _auth = auth,
        super(DayBookState(selectedDate: DateTime.now())) {
    on<DayBookStarted>(_onStarted);
    on<DayBookDateChanged>(_onDateChanged);
    on<DayBookEntryAdded>(_onEntryAdded);
    on<_SummaryUpdated>(_onSummaryUpdated);
  }

  final ComputeDayBookUseCase _computeDayBook;
  final RecordCashEntryUseCase _recordCashEntry;
  final AuthRepository _auth;
  StreamSubscription? _summarySubscription;

  Future<void> _onStarted(DayBookStarted event, Emitter<DayBookState> emit) async {
    final date = event.date ?? state.selectedDate ?? DateTime.now();
    emit(state.copyWith(status: DayBookStatus.loading, selectedDate: date));
    await _subscribeToSummary(date, emit);
  }

  Future<void> _onDateChanged(
      DayBookDateChanged event, Emitter<DayBookState> emit) async {
    emit(state.copyWith(status: DayBookStatus.loading, selectedDate: event.date));
    await _subscribeToSummary(event.date, emit);
  }

  Future<void> _subscribeToSummary(DateTime date, Emitter<DayBookState> emit) async {
    await _summarySubscription?.cancel();
    final userId = _auth.currentSession?.userId;
    if (userId == null) {
      emit(state.copyWith(status: DayBookStatus.failure, errorMessage: 'User not authenticated'));
      return;
    }

    final completer = Completer<void>();
    _summarySubscription = _computeDayBook(userId, date).listen(
      (summary) {
        add(_SummaryUpdated(summary));
        if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        emit(state.copyWith(status: DayBookStatus.failure, errorMessage: e.toString()));
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  // Internal event to handle stream updates
  void _onSummaryUpdated(_SummaryUpdated event, Emitter<DayBookState> emit) {
    emit(state.copyWith(status: DayBookStatus.success, summary: event.summary));
  }

  Future<void> _onEntryAdded(DayBookEntryAdded event, Emitter<DayBookState> emit) async {
    final userId = _auth.currentSession?.userId;
    if (userId == null) return;

    try {
      await _recordCashEntry(
        userId: userId,
        amount: event.amount,
        type: event.type,
        note: event.note,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _summarySubscription?.cancel();
    return super.close();
  }
}

class _SummaryUpdated extends DayBookEvent {
  _SummaryUpdated(this.summary);
  final DayBookSummary summary;
}
