import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

/// Resolves a full inventory product by barcode for POS scan flows.
class ResolveProductForBarcodeUseCase {
  ResolveProductForBarcodeUseCase(this._products);

  final ProductRepository _products;

  Future<Product?> call({
    required String userId,
    required String barcode,
  }) {
    return _products.findByBarcode(userId, barcode);
  }
}
