import 'dart:async';

import 'package:inventopos/core/notifications/local_notification_service.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';

/// Watches in-app notification rows and mirrors new ones to the OS tray.
class NotificationSyncCoordinator {
  NotificationSyncCoordinator(
    this._repository,
    this._local,
  );

  final NotificationsRepository _repository;
  final LocalNotificationService _local;

  StreamSubscription<List<PosNotification>>? _sub;
  final Set<String> _seenIds = {};
  bool _primed = false;
  String? _userId;

  Future<void> start(String userId) async {
    if (_userId == userId && _sub != null) return;
    await stop();
    _userId = userId;
    _primed = false;
    _seenIds.clear();

    await _local.requestPermissions();

    _sub = _repository.watchNotifications(userId).listen(
      _onListUpdated,
      onError: (_) {},
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _userId = null;
    _primed = false;
    _seenIds.clear();
  }

  Future<void> _onListUpdated(List<PosNotification> list) async {
    if (!_primed) {
      _seenIds.addAll(list.map((n) => n.id));
      _primed = true;
      return;
    }

    for (final n in list) {
      if (_seenIds.contains(n.id)) continue;
      _seenIds.add(n.id);
      await _local.show(
        id: n.id.hashCode & 0x7fffffff,
        title: 'Fast Pos',
        body: n.message,
        payload: n.id,
      );
    }

    final currentIds = list.map((n) => n.id).toSet();
    _seenIds.removeWhere((id) => !currentIds.contains(id));
  }

  /// Call after inserting a notification locally (no wait for stream).
  Future<void> notifyImmediately({
    required String id,
    required String message,
  }) async {
    await _local.show(
      id: id.hashCode & 0x7fffffff,
      title: 'Fast Pos',
      body: message,
      payload: id,
    );
    _seenIds.add(id);
  }
}
