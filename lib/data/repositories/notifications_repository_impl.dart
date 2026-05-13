import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id']).eq('user_id', userId);
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }
}
