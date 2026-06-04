import 'package:equatable/equatable.dart';

class ReorderAlert extends Equatable {
  const ReorderAlert({
    required this.productId,
    required this.productName,
    required this.stockQuantity,
    required this.velocityEma,
    required this.daysRemaining,
  });

  final String productId;
  final String productName;
  final int stockQuantity;
  final double velocityEma;
  final double daysRemaining;

  @override
  List<Object?> get props =>
      [productId, productName, stockQuantity, velocityEma, daysRemaining];
}
