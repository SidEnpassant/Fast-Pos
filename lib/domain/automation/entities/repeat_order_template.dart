import 'package:equatable/equatable.dart';

class RepeatOrderTemplate extends Equatable {
  const RepeatOrderTemplate({
    required this.customerId,
    required this.items,
  });

  final String customerId;
  final List<RepeatOrderItem> items;

  @override
  List<Object?> get props => [customerId, items];
}

class RepeatOrderItem extends Equatable {
  const RepeatOrderItem({
    required this.productName,
    required this.lastPrice,
    required this.avgQuantity,
  });

  final String productName;
  final double lastPrice;
  final int avgQuantity;

  @override
  List<Object?> get props => [productName, lastPrice, avgQuantity];
}
