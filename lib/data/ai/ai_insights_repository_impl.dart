import 'package:inventopos/domain/ai/entities/ai_insight.dart';
import 'package:inventopos/domain/ai/repositories/ai_insights_port.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiInsightsRepositoryImpl implements AiInsightsPort {
  AiInsightsRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<List<AiInsight>> watchForUser(String userId) {
    return _client
        .from('ai_insights')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Future<void> markRead(String insightId) async {
    await _client.from('ai_insights').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', insightId);
  }

  @override
  Future<int> unreadCount(String userId) async {
    try {
      final rows = await _client
          .from('ai_insights')
          .select('id')
          .eq('user_id', userId)
          .filter('read_at', 'is', null);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  AiInsight _fromRow(Map<String, dynamic> row) => AiInsight(
        id: row['id']?.toString() ?? '',
        type: row['type']?.toString() ?? 'general',
        title: row['title']?.toString() ?? '',
        body: row['body']?.toString() ?? '',
        dedupKey: row['dedup_key']?.toString() ?? '',
        readAt: row['read_at'] != null
            ? DateTime.parse(row['read_at'].toString())
            : null,
        createdAt: DateTime.parse(
          row['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        ),
      );
}
