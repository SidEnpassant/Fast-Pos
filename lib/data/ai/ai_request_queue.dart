import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/data/local/hive/local_store.dart';
import 'package:uuid/uuid.dart';

/// Offline queue for AI Edge Function calls (replay when online).
class AiRequestQueue {
  AiRequestQueue();

  final _uuid = const Uuid();

  Box<Map> get _box => LocalStore.box(HiveBoxes.aiRequestQueue);

  Future<void> enqueue({
    required String userId,
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    final id = _uuid.v4();
    await _box.put(id, {
      'user_id': userId,
      'function_name': functionName,
      'body_json': jsonEncode(body),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<QueuedAiRequest>> pendingFor(String userId) async {
    final out = <QueuedAiRequest>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      final m = Map<String, dynamic>.from(raw);
      if (m['user_id'] != userId) continue;
      out.add(
        QueuedAiRequest(
          id: key.toString(),
          functionName: m['function_name'] as String,
          body: jsonDecode(m['body_json'] as String) as Map<String, dynamic>,
        ),
      );
    }
    return out;
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }
}

class QueuedAiRequest {
  const QueuedAiRequest({
    required this.id,
    required this.functionName,
    required this.body,
  });

  final String id;
  final String functionName;
  final Map<String, dynamic> body;
}
