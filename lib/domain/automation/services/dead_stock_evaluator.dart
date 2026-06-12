import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/product.dart';

class DeadStockAlert extends Equatable {
  const DeadStockAlert({
    required this.productId,
    required this.productName,
    required this.stockQuantity,
    required this.daysSinceUpdate,
  });

  final String productId;
  final String productName;
  final int stockQuantity;
  final int daysSinceUpdate;

  @override
  List<Object?> get props =>
      [productId, productName, stockQuantity, daysSinceUpdate];
}

abstract final class DeadStockEvaluator {
  static List<DeadStockAlert> evaluate(
    List<Product> products, {
    int staleDays = 30,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: staleDays));
    final alerts = <DeadStockAlert>[];
    for (final p in products) {
      if (!p.isActive) continue;
      if (p.velocityEma > 0) continue;
      if (p.updatedAt.isAfter(cutoff)) continue;
      alerts.add(
        DeadStockAlert(
          productId: p.id,
          productName: p.name,
          stockQuantity: p.stockQuantity,
          daysSinceUpdate: DateTime.now().difference(p.updatedAt).inDays,
        ),
      );
    }
    return alerts;
  }
}
