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
