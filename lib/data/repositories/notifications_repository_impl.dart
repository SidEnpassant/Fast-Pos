import 'package:inventopos/core/notifications/local_notification_service.dart';
import 'package:inventopos/core/supabase/guard_supabase_postgres_stream.dart';
import 'package:inventopos/data/mappers/pos_notification_mapper.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    SupabaseClient? client,
    LocalNotificationService? localNotifications,
  })  : _client = client ?? Supabase.instance.client,
        _local = localNotifications;

  final SupabaseClient _client;
  final LocalNotificationService? _local;

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
    const message = 'You have a payment due for';
    final fullMessage = '$message $customerName.';
    final row = await _insertAndReturn(
      userId: userId,
      message: fullMessage,
    );
    await _showOsNotification(row);
  }

  Future<Map<String, dynamic>> _insertAndReturn({
    required String userId,
    required String message,
  }) async {
    final data = await _client
        .from('notifications')
        .insert({
          'user_id': userId,
          'message': message,
          'is_read': false,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(data);
  }

  Future<void> _showOsNotification(Map<String, dynamic> row) async {
    final local = _local;
    if (local == null) return;
    final n = PosNotificationMapper.fromSupabaseRow(row);
    await local.show(
      id: n.id.hashCode & 0x7fffffff,
      title: 'Fast Pos',
      body: n.message,
      payload: n.id,
    );
  }
}
