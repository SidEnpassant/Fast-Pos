import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/checkout/discount_strategy.dart';

sealed class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

final class CheckoutDiscountAdded extends CheckoutEvent {
  const CheckoutDiscountAdded(this.strategy);

  final DiscountStrategy strategy;

  @override
  List<Object?> get props => [strategy];
}

final class CheckoutDiscountsCleared extends CheckoutEvent {
  const CheckoutDiscountsCleared();
}

final class CheckoutLoyaltyRedemptionToggled extends CheckoutEvent {
  const CheckoutLoyaltyRedemptionToggled(this.isActive);
  final bool isActive;

  @override
  List<Object?> get props => [isActive];
}

final class CheckoutPointsUpdated extends CheckoutEvent {
  const CheckoutPointsUpdated({
    required this.points,
    required this.currencyPerPoint,
  });
  final int points;
  final double currencyPerPoint;

  @override
  List<Object?> get props => [points, currencyPerPoint];
}
