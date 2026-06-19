import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/checkout/discount_strategy.dart';

class CheckoutState extends Equatable {
  const CheckoutState({
    this.activeStrategies = const [],
    this.discountTotal = 0,
    this.breakdown = const [],
    this.isLoyaltyRedemptionActive = false,
    this.availablePoints = 0,
    this.currencyPerPoint = 0,
  });

  final List<DiscountStrategy> activeStrategies;
  final double discountTotal;
  final List<Map<String, dynamic>> breakdown;
  final bool isLoyaltyRedemptionActive;
  final int availablePoints;
  final double currencyPerPoint;

  double get loyaltyDiscount =>
      isLoyaltyRedemptionActive ? availablePoints * currencyPerPoint : 0;

  double get totalDiscount => discountTotal + loyaltyDiscount;

  @override
  List<Object?> get props => [
        activeStrategies,
        discountTotal,
        breakdown,
        isLoyaltyRedemptionActive,
        availablePoints,
        currencyPerPoint,
      ];

  CheckoutState copyWith({
    List<DiscountStrategy>? activeStrategies,
    double? discountTotal,
    List<Map<String, dynamic>>? breakdown,
    bool? isLoyaltyRedemptionActive,
    int? availablePoints,
    double? currencyPerPoint,
  }) {
    return CheckoutState(
      activeStrategies: activeStrategies ?? this.activeStrategies,
      discountTotal: discountTotal ?? this.discountTotal,
      breakdown: breakdown ?? this.breakdown,
      isLoyaltyRedemptionActive:
          isLoyaltyRedemptionActive ?? this.isLoyaltyRedemptionActive,
      availablePoints: availablePoints ?? this.availablePoints,
      currencyPerPoint: currencyPerPoint ?? this.currencyPerPoint,
    );
  }
}
