import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/purchase_order.dart';

enum PurchaseOrderStatus { initial, loading, success, failure }

class PurchaseOrderState extends Equatable {
  final PurchaseOrderStatus status;
  final List<PurchaseOrder> orders;
  final String? errorMessage;

  const PurchaseOrderState({
    this.status = PurchaseOrderStatus.initial,
    this.orders = const [],
    this.errorMessage,
  });

  PurchaseOrderState copyWith({
    PurchaseOrderStatus? status,
    List<PurchaseOrder>? orders,
    String? errorMessage,
  }) {
    return PurchaseOrderState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, orders, errorMessage];
}
