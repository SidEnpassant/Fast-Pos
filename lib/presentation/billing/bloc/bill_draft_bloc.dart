import 'package:bloc/bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_state.dart';

class BillDraftBloc extends Bloc<BillDraftEvent, BillDraftState> {
  BillDraftBloc() : super(const BillDraftState()) {
    on<BillDraftLineAdded>(_onLineAdded);
    on<BillDraftLineRemoved>(_onLineRemoved);
    on<BillDraftCleared>(_onCleared);
  }

  void _onLineAdded(BillDraftLineAdded event, Emitter<BillDraftState> emit) {
    emit(state.copyWith(lines: [...state.lines, event.line]));
  }

  void _onLineRemoved(
      BillDraftLineRemoved event, Emitter<BillDraftState> emit) {
    final next = List.of(state.lines);
    if (event.index < 0 || event.index >= next.length) return;
    next.removeAt(event.index);
    emit(state.copyWith(lines: next));
  }

  void _onCleared(BillDraftCleared event, Emitter<BillDraftState> emit) {
    emit(const BillDraftState());
  }
}
