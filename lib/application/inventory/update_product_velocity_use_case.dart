import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/inventory/velocity_calculator.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

/// Updates EMA velocity after a successful bill for lines with product IDs.
class UpdateProductVelocityUseCase {
  UpdateProductVelocityUseCase(this._products);

  final ProductRepository _products;

  Future<void> call({
    required String userId,
    required List<BillDraftLine> lines,
  }) async {
    final qtyByProduct = <String, double>{};
    for (final line in lines) {
      final id = line.productId;
      if (id == null || id.isEmpty) continue;
      qtyByProduct[id] = (qtyByProduct[id] ?? 0.0) + line.quantity;
    }
    if (qtyByProduct.isEmpty) return;

    final catalog = await _products.fetchProductsForUser(userId);
    final byId = {for (final p in catalog) p.id: p};

    for (final entry in qtyByProduct.entries) {
      final product = byId[entry.key];
      if (product == null) continue;
      final next = VelocityCalculator.nextVelocity(
        previousVelocity: product.velocityEma,
        qtySoldToday: entry.value,
      );
      await _products.updateProduct(
        Product(
          id: product.id,
          userId: product.userId,
          name: product.name,
          sku: product.sku,
          barcode: product.barcode,
          price: product.price,
          costPrice: product.costPrice,
          stockQuantity: product.stockQuantity,
          minStockThreshold: product.minStockThreshold,
          category: product.category,
          isActive: product.isActive,
          velocityEma: next,
          updatedAt: DateTime.now(),
          deletedAt: product.deletedAt,
        ),
      );
    }
  }
}
