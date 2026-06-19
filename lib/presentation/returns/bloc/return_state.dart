import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

class ReturnState extends Equatable {
  const ReturnState({
    this.originalBill,
    this.loading = false,
    this.submitting = false,
    this.success = false,
    this.errorMessage,
    this.returnQuantities = const {},
    this.returnReason = 'Customer Request',
    this.refundMethod = 'cash',
  });

  final Bill? originalBill;
  final bool loading;
  final bool submitting;
  final bool success;
  final String? errorMessage;
  
  // Map of productId to returned quantity
  final Map<String, double> returnQuantities;
  final String returnReason;
  final String refundMethod;

  double get totalRefundAmount {
    if (originalBill == null) return 0.0;
    double total = 0.0;
    for (final line in originalBill!.lineItems) {
      if (line.productId != null) {
        final retQty = returnQuantities[line.productId!] ?? 0.0;
        total += (line.totalPrice / (line.quantity > 0 ? line.quantity : 1)) * retQty;
        // Optionally add tax back if applicable, but for simplicity:
        if (line.quantity > 0) {
           total += (line.taxAmount / line.quantity) * retQty;
        }
      }
    }
    return total;
  }

  ReturnState copyWith({
    Bill? originalBill,
    bool? loading,
    bool? submitting,
    bool? success,
    String? errorMessage,
    Map<String, double>? returnQuantities,
    String? returnReason,
    String? refundMethod,
  }) {
    return ReturnState(
      originalBill: originalBill ?? this.originalBill,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      success: success ?? this.success,
      errorMessage: errorMessage,
      returnQuantities: returnQuantities ?? this.returnQuantities,
      returnReason: returnReason ?? this.returnReason,
      refundMethod: refundMethod ?? this.refundMethod,
    );
  }

  @override
  List<Object?> get props => [
        originalBill,
        loading,
        submitting,
        success,
        errorMessage,
        returnQuantities,
        returnReason,
        refundMethod,
      ];
}
