import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/checkout/discount_strategy.dart';

class CheckoutState extends Equatable {
  const CheckoutState({
    this.activeStrategies = const [],
    this.discountTotal = 0,
    this.breakdown = const [],
  });

  final List<DiscountStrategy> activeStrategies;
  final double discountTotal;
  final List<Map<String, dynamic>> breakdown;

  @override
  List<Object?> get props => [activeStrategies, discountTotal, breakdown];
}
