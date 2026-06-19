import '../../domain/entities/bill.dart';
import '../../domain/loyalty/loyalty_engine.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/loyalty_repository.dart';

class EarnLoyaltyPointsUseCase {
  final LoyaltyRepository _loyaltyRepo;
  final CustomerRepository _customerRepo;

  EarnLoyaltyPointsUseCase(this._loyaltyRepo, this._customerRepo);

  Future<void> call({
    required String userId,
    required String customerId,
    required Bill bill,
  }) async {
    final config = await _loyaltyRepo.getLoyaltyConfig(userId);
    if (!config.isEnabled) return;

    final customer = await _customerRepo.findById(customerId);
    if (customer == null) return;

    final currentTier = LoyaltyEngine.currentTier(customer.lifetimePoints, config.tiers);
    final multiplier = currentTier?.multiplier ?? 1.0;

    final earnedPoints = LoyaltyEngine.computeEarned(bill.totalAmount, multiplier, config);

    if (earnedPoints > 0) {
      await _loyaltyRepo.updateCustomerPoints(customerId, earnedPoints);
      // In a full implementation, we'd also insert into loyalty_transactions here 
      // or via the repository method updateCustomerPoints.
      
      // Update lifetime points (assuming Customer object is mutable/has copyWith)
      final updatedCustomer = customer.copyWith(
        loyaltyPoints: customer.loyaltyPoints + earnedPoints,
        lifetimePoints: customer.lifetimePoints + earnedPoints,
      );
      await _customerRepo.updateCustomer(updatedCustomer);
    }
  }
}