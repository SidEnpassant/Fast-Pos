import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/ai/repositories/ai_insights_port.dart';
import 'package:inventopos/presentation/ai_hub/bloc/ai_hub_event.dart';
import 'package:inventopos/presentation/ai_hub/bloc/ai_hub_state.dart';

class AiHubBloc extends Bloc<AiHubEvent, AiHubState> {
  AiHubBloc(this._observePrefs, this._insights)
      : super(const AiHubState()) {
    on<AiHubStarted>(_onStarted);
    on<AiHubPreferencesReceived>(_onPrefs);
    on<AiHubUnreadCountReceived>(_onUnread);
  }

  final ObserveAiPreferencesUseCase _observePrefs;
  final AiInsightsPort _insights;
  StreamSubscription<AiPreferences>? _prefsSub;

  Future<void> _onStarted(
    AiHubStarted event,
    Emitter<AiHubState> emit,
  ) async {
    await _prefsSub?.cancel();
    emit(state.copyWith(loading: true));
    _prefsSub = _observePrefs(event.userId).listen(
      (p) => add(AiHubPreferencesReceived(p)),
    );
    final count = await _insights.unreadCount(event.userId);
    add(AiHubUnreadCountReceived(count));
  }

  void _onPrefs(
    AiHubPreferencesReceived event,
    Emitter<AiHubState> emit,
  ) {
    emit(state.copyWith(preferences: event.preferences, loading: false));
  }

  void _onUnread(
    AiHubUnreadCountReceived event,
    Emitter<AiHubState> emit,
  ) {
    emit(state.copyWith(unreadInsights: event.count));
  }

  @override
  Future<void> close() async {
    await _prefsSub?.cancel();
    return super.close();
  }
}
