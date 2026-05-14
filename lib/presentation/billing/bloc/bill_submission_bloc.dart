import 'package:bloc/bloc.dart';
import 'package:inventopos/application/billing/submit_bill_use_case.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_state.dart';

class BillSubmissionBloc
    extends Bloc<BillSubmissionEvent, BillSubmissionState> {
  BillSubmissionBloc(this._submitBill) : super(const BillSubmissionIdle()) {
    on<BillSubmissionRequested>(_onSubmit);
    on<BillSubmissionHandled>(_onHandled);
  }

  final SubmitBillUseCase _submitBill;

  Future<void> _onSubmit(
    BillSubmissionRequested event,
    Emitter<BillSubmissionState> emit,
  ) async {
    emit(const BillSubmissionLoading());
    try {
      final result = await _submitBill(event.draft);
      emit(BillSubmissionSuccess(result));
    } catch (e, st) {
      emit(BillSubmissionFailure('$e'));
      addError(e, st);
    }
  }

  void _onHandled(
    BillSubmissionHandled event,
    Emitter<BillSubmissionState> emit,
  ) {
    emit(const BillSubmissionIdle());
  }
}
