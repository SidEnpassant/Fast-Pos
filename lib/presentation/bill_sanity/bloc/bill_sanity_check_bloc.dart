import 'package:bloc/bloc.dart';
import 'package:inventopos/application/automation/automation_use_cases.dart';
import 'package:inventopos/presentation/bill_sanity/bloc/bill_sanity_check_event.dart';
import 'package:inventopos/presentation/bill_sanity/bloc/bill_sanity_check_state.dart';

class BillSanityCheckBloc
    extends Bloc<BillSanityCheckEvent, BillSanityCheckState> {
  BillSanityCheckBloc(this._evaluate) : super(const BillSanityCheckState()) {
    on<BillSanityCheckRequested>(_onRequested);
    on<BillSanityCheckResultReceived>(_onResult);
    on<BillSanityCheckOverrideConfirmed>(_onOverride);
  }

  final EvaluateBillSanityUseCase _evaluate;

  void _onRequested(
    BillSanityCheckRequested event,
    Emitter<BillSanityCheckState> emit,
  ) {
    final result = _evaluate(
      lines: event.lines,
      draftTotal: event.draftTotal,
      recentBills: event.recentBills,
    );
    add(BillSanityCheckResultReceived(result));
  }

  void _onResult(
    BillSanityCheckResultReceived event,
    Emitter<BillSanityCheckState> emit,
  ) {
    emit(state.copyWith(result: event.result, overridden: false));
  }

  void _onOverride(
    BillSanityCheckOverrideConfirmed event,
    Emitter<BillSanityCheckState> emit,
  ) {
    emit(state.copyWith(overridden: true, clearResult: true));
  }
}
