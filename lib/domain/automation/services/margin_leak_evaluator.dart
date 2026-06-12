import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/product.dart';

class MarginLeakAlert extends Equatable {
  const MarginLeakAlert({
    required this.productId,
    required this.productName,
    required this.sellPrice,
    required this.costPrice,
  });

  final String productId;
  final String productName;
  final double sellPrice;
  final double costPrice;

  @override
  List<Object?> get props => [productId, productName, sellPrice, costPrice];
}

abstract final class MarginLeakEvaluator {
  static List<MarginLeakAlert> evaluate(List<Product> products) {
    final alerts = <MarginLeakAlert>[];
    for (final p in products) {
      if (!p.isActive) continue;
      final cost = p.costPrice;
      if (cost == null || cost <= 0) continue;
      if (p.price < cost) {
        alerts.add(
          MarginLeakAlert(
            productId: p.id,
            productName: p.name,
            sellPrice: p.price,
            costPrice: cost,
          ),
        );
      }
    }
    return alerts;
  }
}
