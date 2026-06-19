import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/purchase_order.dart';
import 'package:inventopos/domain/repositories/purchase_order_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  PurchaseOrderRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();
  final Map<String, Future<void>> _pullInFlight = {};
  DateTime? _lastPullAt;

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.purchaseOrders);

  @override
  Stream<List<PurchaseOrder>> watchPurchaseOrdersForUser(String userId) {
    unawaited(_pull(userId));
    return hiveWatchStream(
      events: _box.watch(),
      read: () => _list(userId),
    );
  }

  List<PurchaseOrder> _list(String userId) {
    return _box.values
        .map((m) => _fromMap(Map<String, dynamic>.from(m)))
        .where((po) => po.userId == userId)
        .toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
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
          .from('purchase_orders')
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
      if (kDebugMode) debugPrint('PurchaseOrderRepo._pullOnce failed: $e');
    }
  }

  String _getCursor(String userId) {
    final b = Hive.box<Map>(HiveBoxes.syncCursors);
    return b.get('purchase_orders:$userId')?['last_updated'] as String? ??
        '1970-01-01T00:00:00Z';
  }

  Future<void> _setCursor(String userId, String cursor) async {
    final b = Hive.box<Map>(HiveBoxes.syncCursors);
    await b.put('purchase_orders:$userId', {'last_updated': cursor});
  }

  @override
  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder order) async {
    final id = order.id.isEmpty ? _uuid.v4() : order.id;
    final now = DateTime.now().toUtc().toIso8601String();
    
    final row = {
      'id': id,
      'user_id': order.userId,
      'supplier_id': order.supplierId,
      'supplier_name': order.supplierName,
      'status': order.status,
      'order_date': order.orderDate.toIso8601String(),
      'received_date': order.receivedDate?.toIso8601String(),
      'total_amount': order.totalAmount,
      'notes': order.notes,
      'line_items': order.lineItems.map((e) => {
        'product_id': e.productId,
        'product_name': e.productName,
        'ordered_qty': e.orderedQty,
        'received_qty': e.receivedQty,
        'unit_cost': e.unitCost,
        'uom': e.uom,
      }).toList(),
      'updated_at': now,
    };

    try {
      await _client.from('purchase_orders').insert(row);
    } catch (e) {
      if (kDebugMode) debugPrint('PurchaseOrderRepo.createPurchaseOrder failed: $e');
    }
    
    await _box.put(id, row);
    return _fromMap(row);
  }

  @override
  Future<PurchaseOrder> updatePurchaseOrder(PurchaseOrder order) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    final row = {
      'id': order.id,
      'user_id': order.userId,
      'supplier_id': order.supplierId,
      'supplier_name': order.supplierName,
      'status': order.status,
      'order_date': order.orderDate.toIso8601String(),
      'received_date': order.receivedDate?.toIso8601String(),
      'total_amount': order.totalAmount,
      'notes': order.notes,
      'line_items': order.lineItems.map((e) => {
        'product_id': e.productId,
        'product_name': e.productName,
        'ordered_qty': e.orderedQty,
        'received_qty': e.receivedQty,
        'unit_cost': e.unitCost,
        'uom': e.uom,
      }).toList(),
      'updated_at': now,
    };

    try {
      await _client.from('purchase_orders').update(row).eq('id', order.id);
    } catch (e) {
      if (kDebugMode) debugPrint('PurchaseOrderRepo.updatePurchaseOrder failed: $e');
    }
    
    await _box.put(order.id, row);
    return _fromMap(row);
  }

  @override
  Future<void> receivePurchaseOrder(String orderId, List<PurchaseOrderLine> receivedLines) async {
    final raw = _box.get(orderId);
    if (raw == null) return;
    
    final m = Map<String, dynamic>.from(raw);
    final now = DateTime.now().toUtc().toIso8601String();
    
    m['status'] = 'received';
    m['received_date'] = now;
    m['line_items'] = receivedLines.map((e) => {
        'product_id': e.productId,
        'product_name': e.productName,
        'ordered_qty': e.orderedQty,
        'received_qty': e.receivedQty,
        'unit_cost': e.unitCost,
        'uom': e.uom,
      }).toList();
    m['updated_at'] = now;
    
    await _box.put(orderId, m);
    
    try {
      await _client.from('purchase_orders').update({
        'status': m['status'],
        'received_date': m['received_date'],
        'line_items': m['line_items'],
        'updated_at': m['updated_at'],
      }).eq('id', orderId);
    } catch (e) {
      if (kDebugMode) debugPrint('PurchaseOrderRepo.receivePurchaseOrder failed: $e');
    }
  }

  @override
  Future<void> deletePurchaseOrder(String orderId) async {
    await _box.delete(orderId);
    try {
      await _client.from('purchase_orders').delete().eq('id', orderId);
    } catch (e) {
      if (kDebugMode) debugPrint('PurchaseOrderRepo.deletePurchaseOrder failed: $e');
    }
  }

  PurchaseOrder _fromMap(Map<String, dynamic> m) {
    final lines = (m['line_items'] as List? ?? [])
        .map((l) => PurchaseOrderLine(
              productId: l['product_id'] as String,
              productName: l['product_name'] as String,
              orderedQty: (l['ordered_qty'] as num).toDouble(),
              receivedQty: (l['received_qty'] as num).toDouble(),
              unitCost: (l['unit_cost'] as num).toDouble(),
              uom: l['uom'] as String,
            ))
        .toList();

    return PurchaseOrder(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      supplierId: m['supplier_id'] as String,
      supplierName: m['supplier_name'] as String,
      status: m['status'] as String,
      orderDate: DateTime.parse(m['order_date'] as String),
      receivedDate: m['received_date'] != null
          ? DateTime.parse(m['received_date'] as String)
          : null,
      totalAmount: (m['total_amount'] as num).toDouble(),
      notes: m['notes'] as String?,
      lineItems: lines,
    );
  }
}
