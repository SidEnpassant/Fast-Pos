import 'package:equatable/equatable.dart';

abstract class ReturnEvent extends Equatable {
  const ReturnEvent();

  @override
  List<Object?> get props => [];
}

class ReturnStarted extends ReturnEvent {
  const ReturnStarted(this.billId);
  final String billId;

  @override
  List<Object?> get props => [billId];
}

class ReturnQuantityChanged extends ReturnEvent {
  const ReturnQuantityChanged(this.productId, this.quantity);
  final String productId;
  final double quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

class ReturnReasonChanged extends ReturnEvent {
  const ReturnReasonChanged(this.reason);
  final String reason;

  @override
  List<Object?> get props => [reason];
}

class RefundMethodChanged extends ReturnEvent {
  const RefundMethodChanged(this.method);
  final String method;

  @override
  List<Object?> get props => [method];
}

class ReturnSubmitted extends ReturnEvent {
  const ReturnSubmitted();
}
