import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/loyalty/loyalty_engine.dart';

class LoyaltyConfig extends Equatable {
  const LoyaltyConfig({
    this.isEnabled = false,
    this.pointsPerCurrencyUnit = 1.0,
    this.currencyUnitPerPoint = 0.1, // 10 points = 1 currency unit
    this.minPointsToRedeem = 0,
    this.tiers = const [],
  });

  final bool isEnabled;
  final double pointsPerCurrencyUnit;
  final double currencyUnitPerPoint;
  final int minPointsToRedeem;
  final List<LoyaltyTier> tiers;

  factory LoyaltyConfig.fromJson(Map<String, dynamic> json) {
    return LoyaltyConfig(
      isEnabled: json['enabled'] as bool? ?? json['is_enabled'] as bool? ?? false,
      pointsPerCurrencyUnit: (json['points_per_rupee'] as num?)?.toDouble() ?? (json['points_per_currency_unit'] as num?)?.toDouble() ?? 1.0,
      currencyUnitPerPoint: (json['redemption_rate'] as num?)?.toDouble() ?? (json['currency_unit_per_point'] as num?)?.toDouble() ?? 0.1,
      minPointsToRedeem: (json['min_points_to_redeem'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': isEnabled,
      'points_per_rupee': pointsPerCurrencyUnit,
      'redemption_rate': currencyUnitPerPoint,
      'min_points_to_redeem': minPointsToRedeem,
    };
  }

  @override
  List<Object?> get props => [
        isEnabled,
        pointsPerCurrencyUnit,
        currencyUnitPerPoint,
        minPointsToRedeem,
        tiers,
      ];

  LoyaltyConfig copyWith({
    bool? isEnabled,
    double? pointsPerCurrencyUnit,
    double? currencyUnitPerPoint,
    int? minPointsToRedeem,
    List<LoyaltyTier>? tiers,
  }) {
    return LoyaltyConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      pointsPerCurrencyUnit: pointsPerCurrencyUnit ?? this.pointsPerCurrencyUnit,
      currencyUnitPerPoint: currencyUnitPerPoint ?? this.currencyUnitPerPoint,
      minPointsToRedeem: minPointsToRedeem ?? this.minPointsToRedeem,
      tiers: tiers ?? this.tiers,
    );
  }
}
