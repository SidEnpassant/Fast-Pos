import '../../domain/loyalty/loyalty_engine.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/loyalty_repository.dart';

class RedeemLoyaltyPointsUseCase {
  final LoyaltyRepository _loyaltyRepo;
  final CustomerRepository _customerRepo;

  RedeemLoyaltyPointsUseCase(this._loyaltyRepo, this._customerRepo);

  Future<double> call({
    required String userId,
    required String customerId,
    required int pointsToRedeem,
  }) async {
    if (pointsToRedeem <= 0) return 0.0;

    final config = await _loyaltyRepo.getLoyaltyConfig(userId);
    if (!config.isEnabled) return 0.0;

    final customer = await _customerRepo.findById(customerId);
    if (customer == null || customer.loyaltyPoints < pointsToRedeem) {
      throw StateError('Insufficient loyalty points');
    }

    final discount = LoyaltyEngine.computeRedemptionDiscount(pointsToRedeem, config);
    if (discount > 0) {
      await _loyaltyRepo.updateCustomerPoints(customerId, -pointsToRedeem);
      
      final updatedCustomer = customer.copyWith(
        loyaltyPoints: customer.loyaltyPoints - pointsToRedeem,
      );
      await _customerRepo.updateCustomer(updatedCustomer);
    }
    
    return discount;
  }
}