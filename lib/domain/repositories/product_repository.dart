import 'package:inventopos/domain/entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProductsForUser(String userId);

  Future<List<Product>> fetchProductsForUser(String userId);

  Future<Product?> findByBarcode(String userId, String barcode);

  Future<Product?> findById(String id);

  Future<Product> createProduct({
    required String userId,
    required String name,
    String? sku,
    String? barcode,
    required double price,
    double? costPrice,
    required double stockQuantity,
    required double minStockThreshold,
    String? category,
    String uom = 'piece',
    double? conversionFactor,
    String? hsnCode,
    double gstPercent = 0.0,
  });

  Future<Product> updateProduct(Product product);

  Future<void> deleteProduct(String id);

  Future<List<Product>> searchProducts(String userId, String query);

  Future<void> bulkUpsertLocal(String userId, List<Map<String, dynamic>> rows);

  /// Decrements local Hive stock (offline path).
  Future<void> decrementStockLocal({
    required String productId,
    required double quantity,
  });

  /// Increments local Hive stock when receiving purchase orders or returns.
  Future<void> incrementStockLocal({
    required String productId,
    required double quantity,
  });
}
