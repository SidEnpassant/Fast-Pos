import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/product.dart';

class CheckoutScanState extends Equatable {
  const CheckoutScanState({
    this.locked = false,
    this.lastProduct,
    this.errorMessage,
  });

  final bool locked;
  final Product? lastProduct;
  final String? errorMessage;

  CheckoutScanState copyWith({
    bool? locked,
    Product? lastProduct,
    String? errorMessage,
    bool clearError = false,
    bool clearProduct = false,
  }) {
    return CheckoutScanState(
      locked: locked ?? this.locked,
      lastProduct: clearProduct ? null : (lastProduct ?? this.lastProduct),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [locked, lastProduct, errorMessage];
}
