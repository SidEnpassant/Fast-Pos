import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/stock_audit.dart';
import 'package:inventopos/domain/repositories/stock_audit_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StockAuditRepositoryImpl implements StockAuditRepository {
  StockAuditRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Box<Map> get _auditBox => Hive.box<Map>(HiveBoxes.stockAudits);
  Box<Map> get _lineBox => Hive.box<Map>(HiveBoxes.stockAuditLines);
  Box<Map> get _productBox => Hive.box<Map>(HiveBoxes.products);

  @override
  Stream<List<StockAudit>> watchAudits(String userId) {
    unawaited(_pullAudits(userId));
    return hiveWatchStream(
      events: _auditBox.watch(),
      read: () => _listAudits(userId),
    );
  }

  List<StockAudit> _listAudits(String userId) {
    return _auditBox.values
        .map((m) => _auditFromMap(Map<String, dynamic>.from(m)))
        .where((a) => a.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _pullAudits(String userId) async {
    try {
      final rows = await _client
          .from('stock_audits')
          .select('*, stock_audit_lines(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      for (final raw in rows as List) {
        final m = Map<String, dynamic>.from(raw as Map);
        final lines = (m['stock_audit_lines'] as List?) ?? [];
        m.remove('stock_audit_lines');
        await _auditBox.put(m['id'], m);
        for (final lineRaw in lines) {
          final lm = Map<String, dynamic>.from(lineRaw as Map);
          await _lineBox.put(lm['id'], lm);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('StockAuditRepo._pullAudits failed: $e');
    }
  }

  @override
  Future<StockAudit?> getAuditById(String id) async {
    final raw = _auditBox.get(id);
    if (raw == null) return null;
    return _auditFromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<StockAudit> createAudit(StockAudit audit) async {
    final auditMap = _auditToMap(audit);
    try {
      await _client.from('stock_audits').insert(auditMap);
      
      final linesMaps = audit.lines.map(_lineToMap).toList();
      if (linesMaps.isNotEmpty) {
        await _client.from('stock_audit_lines').insert(linesMaps);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('StockAuditRepo.createAudit failed: $e');
      rethrow;
    }

    await _auditBox.put(audit.id, auditMap);
    for (final line in audit.lines) {
      await _lineBox.put(line.id, _lineToMap(line));
    }
    return audit;
  }

  @override
  Future<void> updateAuditLine(StockAuditLine line) async {
    final lineMap = _lineToMap(line);
    try {
      await _client.from('stock_audit_lines').upsert(lineMap);
    } catch (e) {
      if (kDebugMode) debugPrint('StockAuditRepo.updateAuditLine failed: $e');
      rethrow;
    }
    await _lineBox.put(line.id, lineMap);
  }

  @override
  Future<void> completeAudit(String auditId) async {
    final audit = await getAuditById(auditId);
    if (audit == null) return;

    try {
      await _client.rpc('complete_stock_audit', params: {
        'p_audit_id': auditId,
        'p_notes': audit.notes ?? '',
      });
    } catch (e) {
      if (kDebugMode) debugPrint('StockAuditRepo.completeAudit failed: $e');
      rethrow;
    }

    final updatedAudit = audit.copyWith(
      status: StockAuditStatus.completed,
      completedAt: DateTime.now(),
    );
    await _auditBox.put(auditId, _auditToMap(updatedAudit));
  }

  @override
  Future<void> cancelAudit(String auditId) async {
    try {
      await _client
          .from('stock_audits')
          .update({'status': 'cancelled'}).eq('id', auditId);
    } catch (e) {
      if (kDebugMode) debugPrint('StockAuditRepo.cancelAudit failed: $e');
      rethrow;
    }

    final raw = _auditBox.get(auditId);
    if (raw != null) {
      final m = Map<String, dynamic>.from(raw);
      m['status'] = 'cancelled';
      await _auditBox.put(auditId, m);
    }
  }

  StockAudit _auditFromMap(Map<String, dynamic> m) {
    final id = m['id'] as String;
    final linesRaw = _lineBox.values
        .where((lm) => lm['audit_id'] == id)
        .map((lm) => _lineFromMap(Map<String, dynamic>.from(lm)))
        .toList();

    return StockAudit(
      id: id,
      userId: m['user_id'] as String,
      auditDate: DateTime.parse(m['audit_date'] as String),
      status: StockAuditStatus.values.firstWhere(
        (e) => e.name == (m['status'] as String? ?? 'in_progress').toCamelCase(),
        orElse: () => StockAuditStatus.inProgress,
      ),
      notes: m['notes'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      completedAt: m['completed_at'] != null
          ? DateTime.parse(m['completed_at'] as String)
          : null,
      lines: linesRaw,
    );
  }

  StockAuditLine _lineFromMap(Map<String, dynamic> m) {
    final productId = m['product_id'] as String;
    final productRaw = _productBox.get(productId);
    final productName = productRaw?['name'] as String? ?? 'Unknown Product';

    return StockAuditLine(
      id: m['id'] as String,
      auditId: m['audit_id'] as String,
      productId: productId,
      productName: productName,
      systemQty: (m['system_qty'] as num).toDouble(),
      physicalQty: (m['physical_qty'] as num?)?.toDouble() ?? 0,
      variance: (m['variance'] as num?)?.toDouble() ?? 0,
      note: m['note'] as String?,
    );
  }

  Map<String, dynamic> _auditToMap(StockAudit a) => {
        'id': a.id,
        'user_id': a.userId,
        'audit_date': a.auditDate.toIso8601String(),
        'status': a.status.name.toSnakeCase(),
        'notes': a.notes,
        'created_at': a.createdAt.toIso8601String(),
        'completed_at': a.completedAt?.toIso8601String(),
      };

  Map<String, dynamic> _lineToMap(StockAuditLine l) => {
        'id': l.id,
        'audit_id': l.auditId,
        'product_id': l.productId,
        'system_qty': l.systemQty,
        'physical_qty': l.physicalQty,
        'variance': l.variance,
        'note': l.note,
      };
}

extension on String {
  String toSnakeCase() {
    return replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return '_${match.group(1)!.toLowerCase()}';
    });
  }

  String toCamelCase() {
    final parts = split('_');
    if (parts.isEmpty) return '';
    final first = parts.first;
    final rest = parts.skip(1).map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1);
    });
    return [first, ...rest].join();
  }
}
