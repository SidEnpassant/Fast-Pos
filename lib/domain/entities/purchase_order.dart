import 'package:equatable/equatable.dart';

class PurchaseOrderLine extends Equatable {
  final String productId;
  final String productName;
  final double orderedQty;
  final double receivedQty;
  final double unitCost;
  final String uom;

  const PurchaseOrderLine({
    required this.productId,
    required this.productName,
    required this.orderedQty,
    required this.receivedQty,
    required this.unitCost,
    required this.uom,
  });

  @override
  List<Object?> get props => [productId, productName, orderedQty, receivedQty, unitCost, uom];
}

class PurchaseOrder extends Equatable {
  final String id;
  final String userId;
  final String supplierId;
  final String supplierName;
  final String status;
  final DateTime orderDate;
  final DateTime? receivedDate;
  final double totalAmount;
  final String? notes;
  final List<PurchaseOrderLine> lineItems;

  const PurchaseOrder({
    required this.id,
    required this.userId,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.orderDate,
    this.receivedDate,
    required this.totalAmount,
    this.notes,
    required this.lineItems,
  });

  @override
  List<Object?> get props => [id, userId, supplierId, supplierName, status, orderDate, receivedDate, totalAmount, notes, lineItems];
}