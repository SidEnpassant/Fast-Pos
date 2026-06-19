import 'package:bloc/bloc.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_event.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc() : super(const CheckoutState()) {
    on<CheckoutDiscountAdded>(_onAdded);
    on<CheckoutDiscountsCleared>(_onCleared);
    on<CheckoutLoyaltyRedemptionToggled>(_onLoyaltyToggled);
    on<CheckoutPointsUpdated>(_onPointsUpdated);
  }

  void _onAdded(CheckoutDiscountAdded event, Emitter<CheckoutState> emit) {
    emit(
      state.copyWith(
        activeStrategies: [...state.activeStrategies, event.strategy],
      ),
    );
  }

  void _onCleared(CheckoutDiscountsCleared event, Emitter<CheckoutState> emit) {
    emit(const CheckoutState());
  }

  void _onLoyaltyToggled(
    CheckoutLoyaltyRedemptionToggled event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(isLoyaltyRedemptionActive: event.isActive));
  }

  void _onPointsUpdated(
    CheckoutPointsUpdated event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(
      availablePoints: event.points,
      currencyPerPoint: event.currencyPerPoint,
    ));
  }
}
