import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:uuid/uuid.dart';

class HiveOutboxDao {
  Box<Map> get _box => Hive.box<Map>(HiveBoxes.outbox);
  final _uuid = const Uuid();

  int pendingCount(String userId) {
    return _box.values.where((m) {
      final map = Map<String, dynamic>.from(m);
      return map['user_id'] == userId && map['status'] == 'pending';
    }).length;
  }

  Stream<int> watchPendingCount(String userId) {
    return hiveWatchStream(
      events: _box.watch(),
      read: () => pendingCount(userId),
    );
  }

  Future<String> enqueue({
    required String userId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    final id = _uuid.v4();
    await _box.put(id, {
      'id': id,
      'user_id': userId,
      'operation_type': operationType,
      'payload_json': jsonEncode(payload),
      'retry_count': 0,
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return id;
  }

  List<Map<String, dynamic>> pendingForUser(String userId) {
    return _box.values
        .map((m) => Map<String, dynamic>.from(m))
        .where((m) => m['user_id'] == userId && m['status'] == 'pending')
        .toList()
      ..sort(
        (a, b) =>
            (a['created_at'] as String).compareTo(b['created_at'] as String),
      );
  }

  Future<void> markSynced(String id) async {
    await _box.delete(id);
  }

  Future<void> incrementRetry(String id) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final m = Map<String, dynamic>.from(raw);
    m['retry_count'] = ((m['retry_count'] as num?)?.toInt() ?? 0) + 1;
    await _box.put(id, m);
  }
}
