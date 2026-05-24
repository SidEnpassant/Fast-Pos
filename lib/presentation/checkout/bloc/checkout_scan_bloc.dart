import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:inventopos/application/billing/resolve_product_for_barcode_use_case.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_scan_event.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_scan_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutScanBloc extends Bloc<CheckoutScanEvent, CheckoutScanState> {
  CheckoutScanBloc(this._resolve) : super(const CheckoutScanState()) {
    on<CheckoutScanBarcodeDetected>(_onDetected);
    on<CheckoutScanUnlock>(_onUnlock);
  }

  final ResolveProductForBarcodeUseCase _resolve;

  Future<void> _onDetected(
    CheckoutScanBarcodeDetected event,
    Emitter<CheckoutScanState> emit,
  ) async {
    if (state.locked) return;
    emit(state.copyWith(locked: true, clearError: true));

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      emit(state.copyWith(locked: false, errorMessage: 'Not signed in'));
      add(const CheckoutScanFailed('Not signed in'));
      return;
    }

    final product = await _resolve(userId: uid, barcode: event.barcode);
    if (product == null) {
      emit(state.copyWith(locked: false, errorMessage: 'Not in inventory'));
      add(const CheckoutScanFailed('Not in inventory'));
      return;
    }

    await HapticFeedback.mediumImpact();
    emit(state.copyWith(lastProduct: product, locked: true));
    add(CheckoutScanProductResolved(product));
  }

  void _onUnlock(CheckoutScanUnlock event, Emitter<CheckoutScanState> emit) {
    emit(state.copyWith(locked: false, clearProduct: true, clearError: true));
  }
}
