import 'package:bloc/bloc.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_event.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc() : super(const CheckoutState()) {
    on<CheckoutDiscountAdded>(_onAdded);
    on<CheckoutDiscountsCleared>(_onCleared);
  }

  void _onAdded(CheckoutDiscountAdded event, Emitter<CheckoutState> emit) {
    emit(
      CheckoutState(
        activeStrategies: [...state.activeStrategies, event.strategy],
      ),
    );
  }

  void _onCleared(CheckoutDiscountsCleared event, Emitter<CheckoutState> emit) {
    emit(const CheckoutState());
  }
}
