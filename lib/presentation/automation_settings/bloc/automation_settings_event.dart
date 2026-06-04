import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';

sealed class AutomationSettingsEvent extends Equatable {
  const AutomationSettingsEvent();

  @override
  List<Object?> get props => [];
}

final class AutomationSettingsStarted extends AutomationSettingsEvent {
  const AutomationSettingsStarted(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class AutomationSettingsEnabledToggled extends AutomationSettingsEvent {
  const AutomationSettingsEnabledToggled(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

final class AutomationSettingsDailyBriefToggled extends AutomationSettingsEvent {
  const AutomationSettingsDailyBriefToggled(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

final class AutomationSettingsReorderToggled extends AutomationSettingsEvent {
  const AutomationSettingsReorderToggled(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

final class AutomationSettingsEnhancedToggled extends AutomationSettingsEvent {
  const AutomationSettingsEnhancedToggled(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

final class AutomationSettingsLanguageChanged extends AutomationSettingsEvent {
  const AutomationSettingsLanguageChanged(this.language);
  final String language;

  @override
  List<Object?> get props => [language];
}

final class AutomationSettingsSaveRequested extends AutomationSettingsEvent {
  const AutomationSettingsSaveRequested();
}

final class AutomationSettingsPreferencesReceived extends AutomationSettingsEvent {
  const AutomationSettingsPreferencesReceived(this.preferences);
  final AiPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}
