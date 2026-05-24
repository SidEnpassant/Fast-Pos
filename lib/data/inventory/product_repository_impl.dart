import 'dart:async';

import 'package:inventopos/data/local/hive/hive_product_dao.dart';
import 'package:inventopos/data/mappers/product_mapper.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    SupabaseClient? client,
    HiveProductDao? local,
  })  : _client = client ?? Supabase.instance.client,
        _local = local ?? HiveProductDao();

  final SupabaseClient _client;
  final HiveProductDao _local;
  final _uuid = const Uuid();

  @override
  Stream<List<Product>> watchProductsForUser(String userId) {
    _pullRemote(userId);
    return _local.watchForUser(userId);
  }

  Future<void> _pullRemote(String userId) async {
    try {
      final rows = await _client.from('products').select().eq('user_id', userId);
      final products = (rows as List)
          .map((e) => ProductMapper.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
      await _local.putAll(products);
    } catch (_) {}
  }

  @override
  Future<List<Product>> fetchProductsForUser(String userId) async {
    await _pullRemote(userId);
    return _local.listForUser(userId);
  }

  @override
  Future<Product?> findByBarcode(String userId, String barcode) async {
    final local = _local.findByBarcode(userId, barcode);
    if (local != null) return local;
    try {
      final row = await _client
          .from('products')
          .select()
          .eq('user_id', userId)
          .eq('barcode', barcode)
          .maybeSingle();
      if (row == null) return null;
      final p = ProductMapper.fromRow(Map<String, dynamic>.from(row));
      await _local.put(p);
      return p;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product?> findById(String id) => Future.value(_local.findById(id));

  @override
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
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final row = {
      'id': id,
      'user_id': userId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'min_stock_threshold': minStockThreshold,
      'category': category,
      'is_active': true,
      'velocity_ema': 0,
      'updated_at': now.toUtc().toIso8601String(),
    };
    try {
      await _client.from('products').insert(row);
    } catch (_) {}
    final p = ProductMapper.fromRow(row);
    await _local.put(p);
    return p;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final row = ProductMapper.toRow(product);
    try {
      await _client.from('products').update(row).eq('id', product.id);
    } catch (_) {}
    await _local.put(product);
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (_) {}
    final p = _local.findById(id);
    if (p != null) {
      await _local.put(
        Product(
          id: p.id,
          userId: p.userId,
          name: p.name,
          sku: p.sku,
          barcode: p.barcode,
          price: p.price,
          costPrice: p.costPrice,
          stockQuantity: p.stockQuantity,
          minStockThreshold: p.minStockThreshold,
          category: p.category,
          isActive: false,
          velocityEma: p.velocityEma,
          updatedAt: DateTime.now(),
          deletedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<List<Product>> searchProducts(String userId, String query) async {
    return _local.search(userId, query);
  }

  @override
  Future<void> bulkUpsertLocal(String userId, List<Map<String, dynamic>> rows) async {
    final products = rows.map((r) {
      return Product(
        id: r['id'] as String? ?? _uuid.v4(),
        userId: userId,
        name: r['name'] as String,
        sku: r['sku'] as String?,
        barcode: r['barcode'] as String?,
        price: (r['price'] as num?)?.toDouble() ?? 0,
        costPrice: (r['cost_price'] as num?)?.toDouble(),
        stockQuantity: (r['stock_quantity'] as num?)?.toInt() ?? 0,
        minStockThreshold: (r['min_stock_threshold'] as num?)?.toInt() ?? 5,
        category: r['category'] as String?,
        updatedAt: DateTime.now(),
      );
    }).toList();
    await _local.putAll(products);
    try {
      await _client.rpc('bulk_upsert_products', params: {
        'p_user_id': userId,
        'p_json': rows,
      });
    } catch (_) {}
  }
}
