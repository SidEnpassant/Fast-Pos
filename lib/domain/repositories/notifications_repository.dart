/// Notifications for a given user id.
abstract class NotificationsRepository {
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId);

  Future<void> deleteNotification(String id);
}
