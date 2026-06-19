import 'package:equatable/equatable.dart';

/// Editable product line while composing a bill (maps to `products` JSON in Supabase).
class BillDraftLine extends Equatable {
  const BillDraftLine({
    required this.name,
    required this.price,
    required this.quantity,
    this.comment,
    this.productId,
    this.uom = 'piece',
    this.gstPercent,
    this.hsnCode,
    this.taxAmount = 0.0,
  });

  final String name;
  final double price;
  final double quantity;
  final String? comment;
  final String? productId;
  final String uom;
  final double? gstPercent;
  final String? hsnCode;
  final double taxAmount;

  BillDraftLine copyWith({
    String? name,
    double? price,
    double? quantity,
    String? comment,
    String? productId,
    String? uom,
    double? gstPercent,
    String? hsnCode,
    double? taxAmount,
  }) =>
      BillDraftLine(
        name: name ?? this.name,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        comment: comment ?? this.comment,
        productId: productId ?? this.productId,
        uom: uom ?? this.uom,
        gstPercent: gstPercent ?? this.gstPercent,
        hsnCode: hsnCode ?? this.hsnCode,
        taxAmount: taxAmount ?? this.taxAmount,
      );

  Map<String, dynamic> toProductsJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'uom': uom,
        if (comment != null) 'comment': comment,
        if (productId != null) 'product_id': productId,
        if (gstPercent != null) 'gst_percent': gstPercent,
        if (hsnCode != null) 'hsn_code': hsnCode,
        if (taxAmount > 0) 'tax_amount': taxAmount,
      };

  @override
  List<Object?> get props => [
        name,
        price,
        quantity,
        comment,
        productId,
        uom,
        gstPercent,
        hsnCode,
        taxAmount,
      ];
}
