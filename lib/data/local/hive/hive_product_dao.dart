import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/search/inverted_index_builder.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/data/mappers/product_mapper.dart';
import 'package:inventopos/domain/entities/product.dart';

class HiveProductDao {
  Box<Map> get _box => Hive.box<Map>(HiveBoxes.products);
  Box<Map> get _tokens => Hive.box<Map>(HiveBoxes.searchTokens);

  Stream<List<Product>> watchForUser(String userId) {
    return hiveWatchStream(
      events: _box.watch(),
      read: () => listForUser(userId),
    );
  }

  List<Product> listForUser(String userId) {
    return _box.values
        .map((m) => ProductMapper.fromRow(Map<String, dynamic>.from(m)))
        .where((p) => p.userId == userId && p.deletedAt == null)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> put(Product p) async {
    await _box.put(p.id, ProductMapper.toHiveMap(p));
    await _rebuildTokens(p);
  }

  Future<void> putAll(List<Product> products) async {
    if (products.isEmpty) return;
    final productEntries = <String, Map>{};
    for (final p in products) {
      productEntries[p.id] = ProductMapper.toHiveMap(p);
    }
    await _box.putAll(productEntries);
    await _rebuildAllTokens(products);
  }

  Future<void> _rebuildAllTokens(List<Product> products) async {
    final allTokenEntries = <String, Map>{};
    final allKeysToDelete = <dynamic>[];

    for (final p in products) {
      final prefix = '${p.userId}:${p.id}:';
      final toDelete = _tokens.keys
          .where((k) => k.toString().startsWith(prefix))
          .toList();
      allKeysToDelete.addAll(toDelete);

      for (final token in InvertedIndexBuilder.tokenize(p.name)) {
        allTokenEntries['$prefix$token'] = {
          'user_id': p.userId,
          'product_id': p.id,
          'token': token
        };
      }
      if (p.barcode != null && p.barcode!.isNotEmpty) {
        allTokenEntries['$prefix${p.barcode}'] = {
          'user_id': p.userId,
          'product_id': p.id,
          'token': p.barcode
        };
      }
    }

    if (allKeysToDelete.isNotEmpty) {
      await _tokens.deleteAll(allKeysToDelete);
    }
    if (allTokenEntries.isNotEmpty) {
      await _tokens.putAll(allTokenEntries);
    }
  }

  Product? findByBarcode(String userId, String barcode) {
    for (final raw in _box.values) {
      final m = Map<String, dynamic>.from(raw);
      if (m['user_id'] == userId && m['barcode'] == barcode) {
        return ProductMapper.fromRow(m);
      }
    }
    return null;
  }

  Product? findById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return ProductMapper.fromRow(Map<String, dynamic>.from(raw));
  }

  List<Product> search(String userId, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return listForUser(userId);

    final scores = <String, int>{};
    for (final key in _tokens.keys) {
      final m = Map<String, dynamic>.from(_tokens.get(key)!);
      if (m['user_id'] != userId) continue;
      final token = m['token'] as String? ?? '';
      if (token.startsWith(q) || token.contains(q)) {
        final pid = m['product_id'] as String;
        scores[pid] = (scores[pid] ?? 0) + token.length;
      }
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked
        .map((e) => findById(e.key))
        .whereType<Product>()
        .toList();
  }

  Future<void> _rebuildTokens(Product p) async {
    final prefix = '${p.userId}:${p.id}:';
    final toDelete = _tokens.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    for (final k in toDelete) {
      await _tokens.delete(k);
    }
    for (final token in InvertedIndexBuilder.tokenize(p.name)) {
      await _tokens.put(
        '$prefix$token',
        {'user_id': p.userId, 'product_id': p.id, 'token': token},
      );
    }
    if (p.barcode != null && p.barcode!.isNotEmpty) {
      await _tokens.put(
        '$prefix${p.barcode}',
        {'user_id': p.userId, 'product_id': p.id, 'token': p.barcode},
      );
    }
  }
}
