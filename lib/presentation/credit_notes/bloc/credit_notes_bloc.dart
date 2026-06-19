import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/entities/credit_note.dart';
import 'package:inventopos/domain/repositories/credit_note_repository.dart';

import 'credit_notes_event.dart';
import 'credit_notes_state.dart';

class CreditNotesBloc extends Bloc<CreditNotesEvent, CreditNotesState> {
  CreditNotesBloc(this._repo) : super(const CreditNotesState()) {
    on<CreditNotesStarted>(_onStarted);
    on<CreditNotesUpdated>(_onUpdated);
  }

  final CreditNoteRepository _repo;
  StreamSubscription? _sub;

  void _onStarted(CreditNotesStarted event, Emitter<CreditNotesState> emit) {
    emit(state.copyWith(loading: true));
    _sub?.cancel();
    _sub = _repo.watchCreditNotesForUser(event.userId).listen((notes) {
      add(CreditNotesUpdated(notes));
    });
  }

  void _onUpdated(CreditNotesUpdated event, Emitter<CreditNotesState> emit) {
    final sorted = List<CreditNote>.from(event.notes)
      ..sort((a, b) => b.returnDate.compareTo(a.returnDate));
    emit(state.copyWith(notes: sorted, loading: false));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
