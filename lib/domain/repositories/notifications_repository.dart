import 'package:inventopos/domain/entities/pos_notification.dart';

/// Notifications for a given user id.
abstract class NotificationsRepository {
  Stream<List<PosNotification>> watchNotifications(String userId);

  Future<void> deleteNotification(String id);
}
