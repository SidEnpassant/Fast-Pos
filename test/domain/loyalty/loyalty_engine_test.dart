import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/loyalty/loyalty_config.dart';
import 'package:inventopos/domain/loyalty/loyalty_engine.dart';

void main() {
  group('LoyaltyEngine', () {
    const config = LoyaltyConfig(
      isEnabled: true,
      pointsPerCurrencyUnit: 0.1, // 1 point per 10 currency
      currencyUnitPerPoint: 1.0, // 1 point = 1 currency
      minPointsToRedeem: 50,
    );

    test('computeEarned calculates correctly based on amount, config, and tier multiplier', () {
      // 1000 spent * 0.1 = 100 base points. Tier multiplier 1.5 => 150 points.
      final points = LoyaltyEngine.computeEarned(1000.0, 1.5, config);
      expect(points, 150);
    });

    test('computeEarned returns 0 if config disabled', () {
      const disabledConfig = LoyaltyConfig(isEnabled: false);
      final points = LoyaltyEngine.computeEarned(1000.0, 1.5, disabledConfig);
      expect(points, 0);
    });

    test('computeRedemptionDiscount calculates correctly when points meet minimum threshold', () {
      // 100 points * 1.0 = 100 discount. (100 >= 50 minPoints)
      final discount = LoyaltyEngine.computeRedemptionDiscount(100, config);
      expect(discount, 100.0);
    });

    test('computeRedemptionDiscount returns 0 if below minimum threshold', () {
      final discount = LoyaltyEngine.computeRedemptionDiscount(40, config);
      expect(discount, 0.0);
    });

    test('currentTier resolves to highest matching tier', () {
      final tiers = [
        const LoyaltyTier(name: 'Silver', minPoints: 100, multiplier: 1.2, perks: []),
        const LoyaltyTier(name: 'Gold', minPoints: 500, multiplier: 1.5, perks: []),
        const LoyaltyTier(name: 'Platinum', minPoints: 1000, multiplier: 2.0, perks: []),
      ];

      expect(LoyaltyEngine.currentTier(50, tiers), isNull);
      expect(LoyaltyEngine.currentTier(200, tiers)?.name, 'Silver');
      expect(LoyaltyEngine.currentTier(500, tiers)?.name, 'Gold');
      expect(LoyaltyEngine.currentTier(999, tiers)?.name, 'Gold');
      expect(LoyaltyEngine.currentTier(1500, tiers)?.name, 'Platinum');
    });
  });
}
