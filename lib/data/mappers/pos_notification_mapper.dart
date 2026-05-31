import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/supabase_mappers.dart';

abstract final class PosNotificationMapper {
  static PosNotification fromSupabaseRow(Map<String, dynamic> r) {
    final m = SupabaseMappers.notificationFromRow(r);
    return PosNotification(
      id: m['id'] as String,
      userId: m['userId'] as String,
      message: m['message'] as String? ?? '',
      timestamp: m['timestamp'] as DateTime,
      isRead: m['isRead'] as bool? ?? false,
      dedupKey: m['dedupKey'] as String?,
      type: m['type'] as String?,
    );
  }
}
