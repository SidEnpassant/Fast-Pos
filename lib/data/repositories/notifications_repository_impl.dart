import 'package:inventopos/core/supabase/guard_supabase_postgres_stream.dart';
import 'package:inventopos/data/mappers/pos_notification_mapper.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

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
  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  @override
  Future<void> insertPaymentDueNotification({
    required String userId,
    required String customerName,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'message': 'You have a payment due for $customerName.',
      'is_read': false,
    });
  }
}
