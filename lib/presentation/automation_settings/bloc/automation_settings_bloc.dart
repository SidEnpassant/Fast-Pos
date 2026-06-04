import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/ai/save_ai_preferences_use_case.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/presentation/automation_settings/bloc/automation_settings_event.dart';
import 'package:inventopos/presentation/automation_settings/bloc/automation_settings_state.dart';

class AutomationSettingsBloc
    extends Bloc<AutomationSettingsEvent, AutomationSettingsState> {
  AutomationSettingsBloc(this._observe, this._save)
      : super(const AutomationSettingsState()) {
    on<AutomationSettingsStarted>(_onStarted);
    on<AutomationSettingsPreferencesReceived>(_onReceived);
    on<AutomationSettingsEnabledToggled>(_onEnabled);
    on<AutomationSettingsDailyBriefToggled>(_onDailyBrief);
    on<AutomationSettingsReorderToggled>(_onReorder);
    on<AutomationSettingsEnhancedToggled>(_onEnhanced);
    on<AutomationSettingsLanguageChanged>(_onLanguage);
    on<AutomationSettingsSaveRequested>(_onSave);
  }

  final ObserveAiPreferencesUseCase _observe;
  final SaveAiPreferencesUseCase _save;
  StreamSubscription<AiPreferences>? _sub;

  Future<void> _onStarted(
    AutomationSettingsStarted event,
    Emitter<AutomationSettingsState> emit,
  ) async {
    await _sub?.cancel();
    emit(state.copyWith(loading: true, error: null));
    _sub = _observe(event.userId).listen(
      (p) => add(AutomationSettingsPreferencesReceived(p)),
    );
  }

  void _onReceived(
    AutomationSettingsPreferencesReceived event,
    Emitter<AutomationSettingsState> emit,
  ) {
    emit(state.copyWith(
      preferences: event.preferences,
      loading: false,
    ));
  }

  void _patch(
    Emitter<AutomationSettingsState> emit,
    AiPreferences Function(AiPreferences) patch,
  ) {
    final p = state.preferences;
    if (p == null) return;
    emit(state.copyWith(preferences: patch(p), saved: false));
  }

  void _onEnabled(
    AutomationSettingsEnabledToggled event,
    Emitter<AutomationSettingsState> emit,
  ) =>
      _patch(emit, (p) => p.copyWith(enabled: event.enabled));

  void _onDailyBrief(
    AutomationSettingsDailyBriefToggled event,
    Emitter<AutomationSettingsState> emit,
  ) =>
      _patch(emit, (p) => p.copyWith(dailyBriefEnabled: event.enabled));

  void _onReorder(
    AutomationSettingsReorderToggled event,
    Emitter<AutomationSettingsState> emit,
  ) =>
      _patch(emit, (p) => p.copyWith(reorderAlertsEnabled: event.enabled));

  void _onEnhanced(
    AutomationSettingsEnhancedToggled event,
    Emitter<AutomationSettingsState> emit,
  ) =>
      _patch(emit, (p) => p.copyWith(enhancedContext: event.enabled));

  void _onLanguage(
    AutomationSettingsLanguageChanged event,
    Emitter<AutomationSettingsState> emit,
  ) =>
      _patch(emit, (p) => p.copyWith(language: event.language));

  Future<void> _onSave(
    AutomationSettingsSaveRequested event,
    Emitter<AutomationSettingsState> emit,
  ) async {
    final p = state.preferences;
    if (p == null) return;
    emit(state.copyWith(saving: true, error: null));
    try {
      await _save(p);
      emit(state.copyWith(saving: false, saved: true));
    } catch (e) {
      emit(state.copyWith(saving: false, error: '$e'));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
