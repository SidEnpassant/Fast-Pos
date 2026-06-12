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
    on<AutomationSettingsPartialBillToggled>(_onPartial);
    on<AutomationSettingsCreditAlertsToggled>(_onCredit);
    on<AutomationSettingsReceiptShareToggled>(_onReceipt);
    on<AutomationSettingsThankYouToggled>(_onThankYou);
    on<AutomationSettingsEodSummaryToggled>(_onEod);
    on<AutomationSettingsEnhancedToggled>(_onEnhanced);
    on<AutomationSettingsLanguageChanged>(_onLanguage);
    on<AutomationSettingsOwnerPhoneChanged>(_onOwnerPhone);
    on<AutomationSettingsSupplierPhoneChanged>(_onSupplierPhone);
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
    emit(state.copyWith(preferences: event.preferences, loading: false));
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
      AutomationSettingsEnabledToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(enabled: e.enabled));
  void _onDailyBrief(
      AutomationSettingsDailyBriefToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(dailyBriefEnabled: e.enabled));
  void _onReorder(
      AutomationSettingsReorderToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(reorderAlertsEnabled: e.enabled));
  void _onPartial(
      AutomationSettingsPartialBillToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(partialBillRemindersEnabled: e.enabled));
  void _onCredit(
      AutomationSettingsCreditAlertsToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(creditAlertsEnabled: e.enabled));
  void _onReceipt(
      AutomationSettingsReceiptShareToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(autoReceiptShareEnabled: e.enabled));
  void _onThankYou(
      AutomationSettingsThankYouToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(paymentThankYouEnabled: e.enabled));
  void _onEod(
      AutomationSettingsEodSummaryToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(eodSummaryEnabled: e.enabled));
  void _onEnhanced(
      AutomationSettingsEnhancedToggled e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(enhancedContext: e.enabled));
  void _onLanguage(
      AutomationSettingsLanguageChanged e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(language: e.language));
  void _onOwnerPhone(
      AutomationSettingsOwnerPhoneChanged e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(ownerWhatsAppPhone: e.phone));
  void _onSupplierPhone(
      AutomationSettingsSupplierPhoneChanged e, Emitter<AutomationSettingsState> s) =>
      _patch(s, (p) => p.copyWith(supplierWhatsAppPhone: e.phone));

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
