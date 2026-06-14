import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';

/// Foreground sync worker triggered by connectivity changes.
class SyncCoordinator {
  SyncCoordinator(this._sync, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final SyncRepository _sync;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;

  void start(String userId) {
    _sub?.cancel();
    _timer?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen((_) async {
      await _sync.processOutbox(userId);
    });
    _timer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _sync.processOutbox(userId);
    });
    unawaited(_sync.processOutbox(userId));
  }

  void stop() {
    _sub?.cancel();
    _timer?.cancel();
  }
}
