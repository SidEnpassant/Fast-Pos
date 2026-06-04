import 'package:inventopos/core/notifications/notification_sync_coordinator.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const notificationPollTaskName = 'fastPosNotificationPoll';

const _backgroundPollPendingKey = 'fast_pos_background_poll_pending';

@pragma('vm:entry-point')
void notificationBackgroundCallback() {
  Workmanager().executeTask((task, _) async {
    if (task != notificationPollTaskName) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundPollPendingKey, true);
    return true;
  });
}

/// Returns true if a background poll was scheduled while the app was closed.
Future<bool> consumeBackgroundPollPending() async {
  final prefs = await SharedPreferences.getInstance();
  final pending = prefs.getBool(_backgroundPollPendingKey) ?? false;
  if (pending) await prefs.remove(_backgroundPollPendingKey);
  return pending;
}

/// Registers periodic background notification polling (Android best-effort).
Future<void> registerNotificationBackgroundPoll() async {
  await Workmanager().initialize(notificationBackgroundCallback);
  await Workmanager().registerPeriodicTask(
    notificationPollTaskName,
    notificationPollTaskName,
    frequency: const Duration(minutes: 30),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

/// Polls Supabase for new notifications when app resumes or via workmanager.
class NotificationBackgroundPoll {
  static Future<void> pollWith({
    required String userId,
    required NotificationsRepository repository,
    required NotificationSyncCoordinator coordinator,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notif_last_poll_$userId';
    final lastMs = prefs.getInt(key) ?? 0;
    final since = DateTime.fromMillisecondsSinceEpoch(
      lastMs > 0 ? lastMs : DateTime.now().millisecondsSinceEpoch - 86400000,
    );
    await coordinator.pollCatchUp(userId, since);
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }
}
