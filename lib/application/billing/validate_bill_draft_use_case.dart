import 'package:inventopos/application/billing/validate_bill_line_quantity.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

class ValidateBillDraftUseCase {
  ValidateBillDraftUseCase(this._products);

  final ProductRepository _products;

  /// Returns null if valid, otherwise an error message.
  Future<String?> call(List<BillDraftLine> lines) async {
    if (lines.isEmpty) return 'Add at least one product';

    final stockByProduct = <String, double>{};
    for (final line in lines) {
      final pid = line.productId;
      if (pid == null || pid.isEmpty) continue;

      stockByProduct[pid] ??=
          (await _products.findById(pid))?.stockQuantity ?? 0.0;
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final pid = line.productId;
      if (pid == null || pid.isEmpty) continue;

      final stock = stockByProduct[pid] ?? 0.0;
      final result = ValidateBillLineQuantity.validate(
        quantity: line.quantity,
        availableStock: stock,
        productId: pid,
        existingLines: lines,
        editingIndex: i,
      );
      if (!result.isValid) {
        return '${line.name}: ${result.errorMessage}';
      }
    }
    return null;
  }
}
