import 'package:equatable/equatable.dart';
import '../entities/bill.dart';
import '../entities/credit_note.dart';

class ReturnValidation extends Equatable {
  const ReturnValidation({
    required this.isValid,
    this.errors = const [],
  });

  final bool isValid;
  final List<String> errors;

  @override
  List<Object?> get props => [isValid, errors];

  factory ReturnValidation.success() => const ReturnValidation(isValid: true);
  factory ReturnValidation.failure(List<String> errors) =>
      ReturnValidation(isValid: false, errors: errors);
}

class ReturnPolicy {
  static ReturnValidation validateReturn(
    Bill originalBill,
    List<CreditNoteLine> returnLines,
  ) {
    final List<String> errors = [];

    if (returnLines.isEmpty) {
      errors.add('At least one item must be returned.');
    }

    for (final returnLine in returnLines) {
      final originalItem = originalBill.lineItems.firstWhere(
        (item) => item.productName == returnLine.productName,
        orElse: () => const BillLineItem(
          productName: '',
          quantity: 0,
          totalPrice: 0,
        ),
      );

      if (originalItem.productName.isEmpty) {
        errors.add('Item ${returnLine.productName} was not found in the original bill.');
        continue;
      }

      if (returnLine.quantity > originalItem.quantity) {
        errors.add(
          'Cannot return more than purchased for ${returnLine.productName}. '
          'Purchased: ${originalItem.quantity}, Returning: ${returnLine.quantity}',
        );
      }

      if (returnLine.quantity <= 0) {
        errors.add('Return quantity for ${returnLine.productName} must be greater than zero.');
      }
    }

    return errors.isEmpty
        ? ReturnValidation.success()
        : ReturnValidation.failure(errors);
  }

  static double computeRefund(
    List<CreditNoteLine> returnLines, {
    bool includeGst = true,
  }) {
    return returnLines.fold(0.0, (total, line) {
      return total + line.lineTotal + (includeGst ? line.gstAmount : 0.0);
    });
  }
}
