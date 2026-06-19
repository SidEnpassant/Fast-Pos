import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/purchase_order.dart';

abstract class PurchaseOrderEvent extends Equatable {
  const PurchaseOrderEvent();

  @override
  List<Object?> get props => [];
}

class PurchaseOrdersStarted extends PurchaseOrderEvent {
  final String userId;
  const PurchaseOrdersStarted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PurchaseOrderCreated extends PurchaseOrderEvent {
  final PurchaseOrder order;
  const PurchaseOrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

class PurchaseOrderUpdated extends PurchaseOrderEvent {
  final PurchaseOrder order;
  const PurchaseOrderUpdated(this.order);

  @override
  List<Object?> get props => [order];
}

class PurchaseOrderReceived extends PurchaseOrderEvent {
  final String orderId;
  final List<PurchaseOrderLine> receivedLines;
  const PurchaseOrderReceived(this.orderId, this.receivedLines);

  @override
  List<Object?> get props => [orderId, receivedLines];
}

class PurchaseOrderDeleted extends PurchaseOrderEvent {
  final String orderId;
  const PurchaseOrderDeleted(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
