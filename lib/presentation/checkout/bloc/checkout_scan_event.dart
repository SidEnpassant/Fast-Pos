import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/product.dart';

sealed class CheckoutScanEvent extends Equatable {
  const CheckoutScanEvent();

  @override
  List<Object?> get props => [];
}

final class CheckoutScanBarcodeDetected extends CheckoutScanEvent {
  const CheckoutScanBarcodeDetected(this.barcode);

  final String barcode;

  @override
  List<Object?> get props => [barcode];
}

final class CheckoutScanProductResolved extends CheckoutScanEvent {
  const CheckoutScanProductResolved(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

final class CheckoutScanUnlock extends CheckoutScanEvent {
  const CheckoutScanUnlock();
}

final class CheckoutScanFailed extends CheckoutScanEvent {
  const CheckoutScanFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
