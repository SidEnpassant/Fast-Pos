import 'package:inventopos/domain/ai/entities/reorder_alert.dart';
import 'package:inventopos/domain/inventory/velocity_calculator.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

class EvaluateReorderAlertsUseCase {
  EvaluateReorderAlertsUseCase(this._products);

  final ProductRepository _products;

  Future<List<ReorderAlert>> call(String userId) async {
    final products = await _products.fetchProductsForUser(userId);
    final alerts = <ReorderAlert>[];
    for (final p in products) {
      if (!p.isActive) continue;
      if (!VelocityCalculator.shouldReorder(
        stockQuantity: p.stockQuantity,
        velocity: p.velocityEma,
      )) {
        continue;
      }
      alerts.add(
        ReorderAlert(
          productId: p.id,
          productName: p.name,
          stockQuantity: p.stockQuantity,
          velocityEma: p.velocityEma,
          daysRemaining: VelocityCalculator.daysRemaining(
            stockQuantity: p.stockQuantity,
            velocity: p.velocityEma,
          ),
        ),
      );
    }
    alerts.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return alerts;
  }
}
