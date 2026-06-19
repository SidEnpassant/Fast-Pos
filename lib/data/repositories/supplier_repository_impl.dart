import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/supplier.dart';
import 'package:inventopos/domain/repositories/supplier_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();
  final Map<String, Future<void>> _pullInFlight = {};
  DateTime? _lastPullAt;

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.suppliers);

  @override
  Stream<List<Supplier>> watchSuppliersForUser(String userId) {
    unawaited(_pull(userId));
    return hiveWatchStream(
      events: _box.watch(),
      read: () => _list(userId),
    );
  }

  List<Supplier> _list(String userId) {
    return _box.values
        .map((m) => _fromMap(Map<String, dynamic>.from(m)))
        .where((s) => s.userId == userId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _pull(String userId) async {
    if (_lastPullAt != null &&
        DateTime.now().difference(_lastPullAt!) < const Duration(seconds: 30)) {
      return;
    }

    final inFlight = _pullInFlight[userId];
    if (inFlight != null) return inFlight;

    final future = _pullOnce(userId);
    _pullInFlight[userId] = future;
    try {
      await future;
      _lastPullAt = DateTime.now();
    } finally {
      if (identical(_pullInFlight[userId], future)) {
        _pullInFlight.remove(userId);
      }
    }
  }

  Future<void> _pullOnce(String userId) async {
    try {
      final cursor = _getCursor(userId);
      final rows = await _client
          .from('suppliers')
          .select()
          .eq('user_id', userId)
          .gt('updated_at', cursor)
          .order('updated_at');

      String? latest = cursor;
      for (final raw in rows as List) {
        final m = Map<String, dynamic>.from(raw as Map);
        await _box.put(m['id'], m);
        final updatedAt = m['updated_at'] as String;
        if (latest == null || updatedAt.compareTo(latest) > 0) {
          latest = updatedAt;
        }
      }
      if (latest != cursor) {
        await _setCursor(userId, latest!);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SupplierRepo._pullOnce failed: $e');
    }
  }

  String _getCursor(String userId) {
    final b = Hive.box<Map>(HiveBoxes.syncCursors);
    return b.get('suppliers:$userId')?['last_updated'] as String? ??
        '1970-01-01T00:00:00Z';
  }

  Future<void> _setCursor(String userId, String cursor) async {
    final b = Hive.box<Map>(HiveBoxes.syncCursors);
    await b.put('suppliers:$userId', {'last_updated': cursor});
  }

  @override
  Future<Supplier> createSupplier(Supplier supplier) async {
    final id = supplier.id.isEmpty ? _uuid.v4() : supplier.id;
    final now = DateTime.now().toUtc().toIso8601String();
    
    final row = {
      'id': id,
      'user_id': supplier.userId,
      'name': supplier.name,
      'phone': supplier.phone,
      'email': supplier.email,
      'gstin': supplier.gstin,
      'address': supplier.address,
      'updated_at': now,
    };

    try {
      await _client.from('suppliers').insert(row);
    } catch (e) {
      if (kDebugMode) debugPrint('SupplierRepo.createSupplier failed: $e');
    }
    
    await _box.put(id, row);
    return _fromMap(row);
  }

  @override
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    final row = {
      'id': supplier.id,
      'user_id': supplier.userId,
      'name': supplier.name,
      'phone': supplier.phone,
      'email': supplier.email,
      'gstin': supplier.gstin,
      'address': supplier.address,
      'updated_at': now,
    };

    try {
      await _client.from('suppliers').update(row).eq('id', supplier.id);
    } catch (e) {
      if (kDebugMode) debugPrint('SupplierRepo.updateSupplier failed: $e');
    }
    
    await _box.put(supplier.id, row);
    return _fromMap(row);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await _box.delete(id);
    try {
      await _client.from('suppliers').delete().eq('id', id);
    } catch (e) {
      if (kDebugMode) debugPrint('SupplierRepo.deleteSupplier failed: $e');
    }
  }

  @override
  Future<Supplier?> findById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<Supplier>> searchSuppliers(String userId, String query) async {
    final lowerQuery = query.toLowerCase();
    return _list(userId).where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
             (s.phone ?? '').contains(lowerQuery) ||
             (s.email ?? '').toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Supplier _fromMap(Map<String, dynamic> m) => Supplier(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        gstin: m['gstin'] as String?,
        address: m['address'] as String?,
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
