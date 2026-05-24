import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/supabase_mappers.dart';

abstract final class ProductMapper {
  static Product fromRow(Map<String, dynamic> r) {
    return Product(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      name: r['name'] as String,
      sku: r['sku'] as String?,
      barcode: r['barcode'] as String?,
      price: (r['price'] as num?)?.toDouble() ?? 0,
      costPrice: (r['cost_price'] as num?)?.toDouble(),
      stockQuantity: (r['stock_quantity'] as num?)?.toInt() ?? 0,
      minStockThreshold: (r['min_stock_threshold'] as num?)?.toInt() ?? 5,
      category: r['category'] as String?,
      isActive: r['is_active'] as bool? ?? true,
      velocityEma: (r['velocity_ema'] as num?)?.toDouble() ?? 0,
      updatedAt: SupabaseMappers.parseDate(r['updated_at']),
      deletedAt: r['deleted_at'] != null
          ? SupabaseMappers.parseDate(r['deleted_at'])
          : null,
    );
  }

  static Map<String, dynamic> toRow(Product p) => {
        'id': p.id,
        'user_id': p.userId,
        'name': p.name,
        'sku': p.sku,
        'barcode': p.barcode,
        'price': p.price,
        'cost_price': p.costPrice,
        'stock_quantity': p.stockQuantity,
        'min_stock_threshold': p.minStockThreshold,
        'category': p.category,
        'is_active': p.isActive,
        'velocity_ema': p.velocityEma,
        'updated_at': p.updatedAt.toUtc().toIso8601String(),
        'deleted_at': p.deletedAt?.toUtc().toIso8601String(),
      };

  static Map<String, dynamic> toHiveMap(Product p) => toRow(p);
}
