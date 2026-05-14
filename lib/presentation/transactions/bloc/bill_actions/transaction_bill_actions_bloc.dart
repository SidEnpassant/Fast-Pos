import 'package:bloc/bloc.dart';
import 'package:inventopos/application/billing/delete_bill_use_case.dart';
import 'package:inventopos/application/billing/replace_signed_bill_use_case.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_state.dart';

class TransactionBillActionsBloc
    extends Bloc<TransactionBillActionsEvent, TransactionBillActionsState> {
  TransactionBillActionsBloc({
    required ReplaceSignedBillUseCase replaceSignedBill,
    required DeleteBillUseCase deleteBill,
  })  : _replaceSignedBill = replaceSignedBill,
        _deleteBill = deleteBill,
        super(const TransactionBillActionsState()) {
    on<TransactionBillReplaceSignedRequested>(_onReplaceSigned);
    on<TransactionBillDeleteRequested>(_onDelete);
    on<TransactionBillActionsFeedbackConsumed>(_onFeedbackConsumed);
  }

  final ReplaceSignedBillUseCase _replaceSignedBill;
  final DeleteBillUseCase _deleteBill;

  Future<void> _onReplaceSigned(
    TransactionBillReplaceSignedRequested event,
    Emitter<TransactionBillActionsState> emit,
  ) async {
    emit(const TransactionBillActionsState(phase: TransactionBillActionsPhase.busy));
    try {
      await _replaceSignedBill(
        billId: event.billId,
        localFilePath: event.localFilePath,
      );
      emit(
        const TransactionBillActionsState(
          phase: TransactionBillActionsPhase.success,
          message: 'Signed bill updated successfully',
        ),
      );
    } catch (e) {
      emit(
        TransactionBillActionsState(
          phase: TransactionBillActionsPhase.failure,
          message: 'Error updating signed bill: $e',
        ),
      );
    }
  }

  Future<void> _onDelete(
    TransactionBillDeleteRequested event,
    Emitter<TransactionBillActionsState> emit,
  ) async {
    emit(const TransactionBillActionsState(phase: TransactionBillActionsPhase.busy));
    try {
      await _deleteBill(event.billId);
      emit(
        const TransactionBillActionsState(
          phase: TransactionBillActionsPhase.success,
          message:
              'Transaction and associated bill deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        TransactionBillActionsState(
          phase: TransactionBillActionsPhase.failure,
          message: 'Error deleting transaction: $e',
        ),
      );
    }
  }

  void _onFeedbackConsumed(
    TransactionBillActionsFeedbackConsumed event,
    Emitter<TransactionBillActionsState> emit,
  ) {
    emit(const TransactionBillActionsState());
  }
}
