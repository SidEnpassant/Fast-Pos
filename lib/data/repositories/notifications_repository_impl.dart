import 'package:inventopos/core/supabase/guard_supabase_postgres_stream.dart';
import 'package:inventopos/data/mappers/pos_notification_mapper.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<List<PosNotification>> watchNotifications(String userId) {
    return guardSupabasePostgresStream(
      _client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map(
            (rows) => rows.map(PosNotificationMapper.fromSupabaseRow).toList(),
          ),
    );
  }

  @override
  Future<List<PosNotification>> fetchSince(String userId, DateTime since) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .gt('timestamp', since.toUtc().toIso8601String())
        .order('timestamp');
    return (rows as List)
        .map((e) => PosNotificationMapper.fromSupabaseRow(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  @override
  Future<void> insertPaymentDueNotification({
    required String userId,
    required String customerName,
  }) async {
    // Server-side only — no client insert to avoid duplicates.
  }
}
