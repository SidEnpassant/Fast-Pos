import 'package:inventopos/domain/billing/bill_draft_line.dart';

/// Result of validating a bill line quantity against stock and draft totals.
class BillLineQuantityValidation {
  const BillLineQuantityValidation({
    required this.isValid,
    this.errorMessage,
    this.maxAllowed,
  });

  final bool isValid;
  final String? errorMessage;
  final int? maxAllowed;
}

/// Validates integer quantity for a catalog or manual bill line.
abstract final class ValidateBillLineQuantity {
  static BillLineQuantityValidation validate({
    required int quantity,
    int? availableStock,
    String? productId,
    required List<BillDraftLine> existingLines,
    int? editingIndex,
  }) {
    if (quantity < 1) {
      return const BillLineQuantityValidation(
        isValid: false,
        errorMessage: 'Quantity must be at least 1',
      );
    }

    if (productId == null || productId.isEmpty || availableStock == null) {
      return BillLineQuantityValidation(isValid: true, maxAllowed: null);
    }

    var draftQty = 0;
    for (var i = 0; i < existingLines.length; i++) {
      if (editingIndex != null && i == editingIndex) continue;
      final line = existingLines[i];
      if (line.productId == productId) {
        draftQty += line.quantity;
      }
    }

    final maxAllowed = availableStock - draftQty;
    if (quantity > maxAllowed) {
      return BillLineQuantityValidation(
        isValid: false,
        errorMessage: maxAllowed <= 0
            ? 'No stock left for this product'
            : 'Only $maxAllowed available',
        maxAllowed: maxAllowed.clamp(0, availableStock),
      );
    }

    return BillLineQuantityValidation(
      isValid: true,
      maxAllowed: maxAllowed,
    );
  }
}
