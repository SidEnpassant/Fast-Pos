import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.userId,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.costPrice,
    required this.stockQuantity,
    required this.minStockThreshold,
    this.category,
    this.isActive = true,
    this.velocityEma = 0,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final double? costPrice;
  final int stockQuantity;
  final int minStockThreshold;
  final String? category;
  final bool isActive;
  final double velocityEma;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isLowStock => stockQuantity <= minStockThreshold;

  double daysRemaining(double velocity) {
    if (velocity <= 0) return double.infinity;
    return stockQuantity / velocity;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        sku,
        barcode,
        price,
        costPrice,
        stockQuantity,
        minStockThreshold,
        category,
        isActive,
        velocityEma,
        updatedAt,
        deletedAt,
      ];
}
