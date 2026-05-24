import 'package:equatable/equatable.dart';

/// Editable product line while composing a bill (maps to `products` JSON in Supabase).
class BillDraftLine extends Equatable {
  const BillDraftLine({
    required this.name,
    required this.price,
    required this.quantity,
    this.comment,
    this.productId,
  });

  final String name;
  final double price;
  final int quantity;
  final String? comment;
  final String? productId;

  Map<String, dynamic> toProductsJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        if (comment != null) 'comment': comment,
        if (productId != null) 'product_id': productId,
      };

  @override
  List<Object?> get props => [name, price, quantity, comment, productId];
}
