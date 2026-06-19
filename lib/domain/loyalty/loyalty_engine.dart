import '../loyalty/loyalty_config.dart';

class LoyaltyTier {
  final String name;
  final int minPoints;
  final double multiplier;
  final List<String> perks;

  const LoyaltyTier({
    required this.name,
    required this.minPoints,
    required this.multiplier,
    required this.perks,
  });

  factory LoyaltyTier.fromJson(Map<String, dynamic> json) {
    return LoyaltyTier(
      name: json['name'] as String,
      minPoints: json['min_points'] as int,
      multiplier: (json['multiplier'] as num).toDouble(),
      perks: List<String>.from(json['perks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'min_points': minPoints,
      'multiplier': multiplier,
      'perks': perks,
    };
  }
}

class LoyaltyEngine {
  /// Computes earned points based on bill amount, config, and tier multiplier.
  static int computeEarned(double billAmount, double tierMultiplier, LoyaltyConfig config) {
    if (!config.isEnabled || config.pointsPerCurrencyUnit <= 0) return 0;
    // e.g. 1 point per 100 Rs spent -> points_per_rupee = 0.01
    final basePoints = billAmount * config.pointsPerCurrencyUnit;
    return (basePoints * tierMultiplier).floor();
  }

  /// Computes discount amount for given points.
  static double computeRedemptionDiscount(int pointsToRedeem, LoyaltyConfig config) {
    if (!config.isEnabled || pointsToRedeem < config.minPointsToRedeem) return 0.0;
    // e.g. 1 point = 0.1 Rs -> redemption_rate = 0.1
    return pointsToRedeem * config.currencyUnitPerPoint;
  }

  /// Computes current tier based on lifetime points.
  static LoyaltyTier? currentTier(int totalPoints, List<LoyaltyTier> tiers) {
    if (tiers.isEmpty) return null;
    
    // Sort tiers by minPoints descending
    final sortedTiers = List<LoyaltyTier>.from(tiers)
      ..sort((a, b) => b.minPoints.compareTo(a.minPoints));

    for (final tier in sortedTiers) {
      if (totalPoints >= tier.minPoints) {
        return tier;
      }
    }
    
    return null;
  }
}
