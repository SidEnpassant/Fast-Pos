import 'package:inventopos/domain/loyalty/loyalty_config.dart';

abstract class LoyaltyRepository {
  Future<LoyaltyConfig> getLoyaltyConfig(String userId);
  Future<void> saveLoyaltyConfig(String userId, LoyaltyConfig config);
  Future<void> updateCustomerPoints(String customerId, int pointsChange);
}
