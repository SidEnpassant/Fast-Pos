import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/returns/process_return_use_case.dart';
import 'package:inventopos/domain/entities/credit_note.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/presentation/returns/bloc/return_event.dart';
import 'package:inventopos/presentation/returns/bloc/return_state.dart';

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  ReturnBloc(this._billsRepo, this._processReturnUseCase, this._authRepo)
      : super(const ReturnState()) {
    on<ReturnStarted>(_onStarted);
    on<ReturnQuantityChanged>(_onQuantityChanged);
    on<ReturnReasonChanged>(_onReasonChanged);
    on<RefundMethodChanged>(_onRefundMethodChanged);
    on<ReturnSubmitted>(_onSubmitted);
  }

  final BillsRepository _billsRepo;
  final ProcessReturnUseCase _processReturnUseCase;
  final AuthRepository _authRepo;

  Future<void> _onStarted(
    ReturnStarted event,
    Emitter<ReturnState> emit,
  ) async {
    if (event.billId.isEmpty) {
      emit(state.copyWith(loading: false, originalBill: null));
      return;
    }

    emit(state.copyWith(loading: true, errorMessage: null));
    try {
      final bill = await _billsRepo.fetchBillById(event.billId);
      if (bill != null) {
        emit(state.copyWith(loading: false, originalBill: bill));
      } else {
        emit(state.copyWith(
          loading: false,
          errorMessage: 'Bill not found.',
        ));
        emit(state.copyWith(errorMessage: null)); // reset after emitting so snackbar doesn't stick
      }
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        errorMessage: 'Failed to load bill: $e',
      ));
      emit(state.copyWith(errorMessage: null)); // reset
    }
  }

  void _onQuantityChanged(
    ReturnQuantityChanged event,
    Emitter<ReturnState> emit,
  ) {
    final newQtys = Map<String, double>.from(state.returnQuantities);
    if (event.quantity <= 0) {
      newQtys.remove(event.productId);
    } else {
      newQtys[event.productId] = event.quantity;
    }
    emit(state.copyWith(returnQuantities: newQtys));
  }

  void _onReasonChanged(ReturnReasonChanged event, Emitter<ReturnState> emit) {
    emit(state.copyWith(returnReason: event.reason));
  }

  void _onRefundMethodChanged(
      RefundMethodChanged event, Emitter<ReturnState> emit) {
    emit(state.copyWith(refundMethod: event.method));
  }

  Future<void> _onSubmitted(
    ReturnSubmitted event,
    Emitter<ReturnState> emit,
  ) async {
    if (state.originalBill == null) return;
    if (state.returnQuantities.isEmpty) {
      emit(state.copyWith(errorMessage: 'Select at least one item to return.'));
      emit(state.copyWith(errorMessage: null)); // reset
      return;
    }

    final userId = _authRepo.currentSession?.userId;
    if (userId == null) {
      emit(state.copyWith(errorMessage: 'Not authenticated.'));
      emit(state.copyWith(errorMessage: null));
      return;
    }

    emit(state.copyWith(submitting: true, errorMessage: null));

    try {
      final List<CreditNoteLine> returnLines = [];
      for (final line in state.originalBill!.lineItems) {
        if (line.productId == null) continue;
        final retQty = state.returnQuantities[line.productId!] ?? 0.0;
        if (retQty > 0) {
          returnLines.add(CreditNoteLine(
            productId: line.productId!,
            productName: line.productName,
            quantity: retQty,
            unitPrice: (line.totalPrice / (line.quantity > 0 ? line.quantity : 1)),
            lineTotal: (line.totalPrice / (line.quantity > 0 ? line.quantity : 1)) * retQty,
            gstAmount: line.quantity > 0 ? (line.taxAmount / line.quantity) * retQty : 0.0,
          ));
        }
      }

      await _processReturnUseCase(
        originalBill: state.originalBill!,
        returnLines: returnLines,
        refundMethod: state.refundMethod,
        reason: state.returnReason,
      );

      emit(state.copyWith(submitting: false, success: true));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        errorMessage: 'Failed to process return: $e',
      ));
      emit(state.copyWith(errorMessage: null));
    }
  }
}
