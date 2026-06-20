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
    this.hsnCode,
    this.gstPercent = 0.0,
    this.uom = 'piece',
    this.conversionFactor,
  });

  final String id;
  final String userId;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final double? costPrice;
  final double stockQuantity;
  final double minStockThreshold;
  final String? category;
  final bool isActive;
  final double velocityEma;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? hsnCode;
  final double gstPercent;
  final String uom;
  final double? conversionFactor;

  Product copyWith({
    String? id,
    String? userId,
    String? name,
    String? sku,
    String? barcode,
    double? price,
    double? costPrice,
    double? stockQuantity,
    double? minStockThreshold,
    String? category,
    bool? isActive,
    double? velocityEma,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? hsnCode,
    double? gstPercent,
    String? uom,
    double? conversionFactor,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      velocityEma: velocityEma ?? this.velocityEma,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hsnCode: hsnCode ?? this.hsnCode,
      gstPercent: gstPercent ?? this.gstPercent,
      uom: uom ?? this.uom,
      conversionFactor: conversionFactor ?? this.conversionFactor,
    );
  }

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
        hsnCode,
        gstPercent,
        uom,
        conversionFactor,
      ];
}
