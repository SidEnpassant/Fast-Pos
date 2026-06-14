import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:inventopos/application/ai/replay_offline_ai_queue_use_case.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_event.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc(this._sync, this._replayAi)
      : _connectivity = Connectivity(),
        super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityStatusChanged>(_onStatusChanged);
    on<ConnectivityPendingCountChanged>(_onPendingChanged);
  }

  final SyncRepository _sync;
  final ReplayOfflineAiQueueUseCase _replayAi;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<int>? _pendingSub;

  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    await _connectivitySub?.cancel();
    await _pendingSub?.cancel();

    final online = await _sync.isOnline();
    emit(state.copyWith(isOnline: online));

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      add(ConnectivityStatusChanged(isOnline: online));
      if (online) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          unawaited(_sync.processOutbox(uid));
          unawaited(_replayAi(uid));
        }
      }
    });

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      _pendingSub = _sync.watchPendingOutboxCount(uid).listen((count) {
        add(ConnectivityPendingCountChanged(count));
      });
    }
  }

  void _onStatusChanged(
    ConnectivityStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(state.copyWith(isOnline: event.isOnline));
  }

  void _onPendingChanged(
    ConnectivityPendingCountChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(state.copyWith(pendingSyncCount: event.count));
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _pendingSub?.cancel();
    return super.close();
  }
}
