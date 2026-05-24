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
    required int stockQuantity,
    required int minStockThreshold,
    String? category,
  });

  Future<Product> updateProduct(Product product);

  Future<void> deleteProduct(String id);

  Future<List<Product>> searchProducts(String userId, String query);

  Future<void> bulkUpsertLocal(String userId, List<Map<String, dynamic>> rows);
}
