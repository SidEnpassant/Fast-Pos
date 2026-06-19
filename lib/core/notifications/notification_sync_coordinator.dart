import 'dart:async';

import 'package:inventopos/core/notifications/local_notification_service.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';

/// Single OS notification path: stream + dedup by id and dedup_key.
class NotificationSyncCoordinator {
  NotificationSyncCoordinator(
    this._repository,
    this._local,
  );

  final NotificationsRepository _repository;
  final LocalNotificationService _local;

  StreamSubscription<List<PosNotification>>? _sub;
  final Set<String> _seenIds = {};
  final Set<String> _seenDedupKeys = {};
  bool _primed = false;
  String? _userId;

  Future<void> start(String userId) async {
    if (_userId == userId && _sub != null) return;
    await stop();
    _userId = userId;
    _primed = false;
    _seenIds.clear();
    _seenDedupKeys.clear();

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
    _seenDedupKeys.clear();
  }

  Future<void> pollCatchUp(String userId, DateTime since) async {
    final list = await _repository.fetchSince(userId, since);
    for (final n in list) {
      await _maybeShow(n);
    }
  }

  Future<void> _onListUpdated(List<PosNotification> list) async {
    if (!_primed) {
      for (final n in list) {
        _seenIds.add(n.id);
        if (n.dedupKey != null) _seenDedupKeys.add(n.dedupKey!);
      }
      _primed = true;
      return;
    }

    for (final n in list) {
      await _maybeShow(n);
    }

    final currentIds = list.map((n) => n.id).toSet();
    _seenIds.removeWhere((id) => !currentIds.contains(id));

    final currentDedupKeys =
        list.where((n) => n.dedupKey != null).map((n) => n.dedupKey!).toSet();
    _seenDedupKeys.removeWhere((k) => !currentDedupKeys.contains(k));
  }

  Future<void> _maybeShow(PosNotification n) async {
    if (_seenIds.contains(n.id)) return;
    if (n.dedupKey != null && _seenDedupKeys.contains(n.dedupKey)) return;

    _seenIds.add(n.id);
    if (n.dedupKey != null) _seenDedupKeys.add(n.dedupKey!);

    await _local.show(
      id: n.id.hashCode & 0x7fffffff,
      title: 'Fast Pos',
      body: n.message,
      payload: n.id,
    );
  }
}
