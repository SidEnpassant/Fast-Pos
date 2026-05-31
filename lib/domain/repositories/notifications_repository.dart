import 'package:inventopos/domain/entities/pos_notification.dart';

abstract class NotificationsRepository {
  Stream<List<PosNotification>> watchNotifications(String userId);

  Future<void> deleteNotification(String id);

  /// Fetch notifications created after [since] for background poll.
  Future<List<PosNotification>> fetchSince(String userId, DateTime since);

  @Deprecated('Use server-side Edge Functions with dedup_key')
  Future<void> insertPaymentDueNotification({
    required String userId,
    required String customerName,
  });
}
