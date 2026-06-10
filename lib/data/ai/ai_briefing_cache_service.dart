import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/ai/entities/ai_briefing.dart';
import 'package:inventopos/domain/ai/entities/ai_insight.dart';

/// Persists the latest AI briefing in Hive so it survives app restarts.
///
/// Structure (keyed by userId):
/// ```json
/// {
///   "markdown": "…",
///   "insights": [ { "id": …, "type": …, "title": …, … } ],
///   "generatedAt": "2026-06-11T01:08:00.000Z"
/// }
/// ```
class AiBriefingCacheService {
  static const _keyPrefix = 'brief_';

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.aiBriefingCache);

  String _key(String userId) => '$_keyPrefix$userId';

  /// Save briefing to local cache with current timestamp.
  void saveBriefing(String userId, AiBriefing briefing) {
    _box.put(_key(userId), {
      'markdown': briefing.markdown,
      'insights': briefing.insights
          .map((i) => {
                'id': i.id,
                'type': i.type,
                'title': i.title,
                'body': i.body,
                'dedupKey': i.dedupKey,
                'readAt': i.readAt?.toIso8601String(),
                'createdAt': i.createdAt.toIso8601String(),
              })
          .toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Load cached briefing for this user (returns null if none cached).
  AiBriefing? loadBriefing(String userId) {
    final raw = _box.get(_key(userId));
    if (raw == null) return null;
    final md = raw['markdown'] as String?;
    if (md == null || md.trim().isEmpty) return null;

    final insightsRaw = raw['insights'];
    final insights = <AiInsight>[];
    if (insightsRaw is List) {
      for (final item in insightsRaw) {
        if (item is Map) {
          insights.add(AiInsight(
            id: item['id']?.toString() ?? '',
            type: item['type']?.toString() ?? '',
            title: item['title']?.toString() ?? '',
            body: item['body']?.toString() ?? '',
            dedupKey: item['dedupKey']?.toString() ?? '',
            readAt: item['readAt'] != null
                ? DateTime.tryParse(item['readAt'].toString())
                : null,
            createdAt: DateTime.tryParse(
                  item['createdAt']?.toString() ?? '',
                ) ??
                DateTime.now(),
          ));
        }
      }
    }

    return AiBriefing(markdown: md, insights: insights);
  }

  /// Returns the ISO 8601 timestamp of the last cached briefing, or null.
  DateTime? lastGeneratedAt(String userId) {
    final raw = _box.get(_key(userId));
    if (raw == null) return null;
    final ts = raw['generatedAt'] as String?;
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  /// Clears cached briefing for the user.
  void clearBriefing(String userId) {
    _box.delete(_key(userId));
  }
}
