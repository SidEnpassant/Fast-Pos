import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';

class AutomationSettingsState extends Equatable {
  const AutomationSettingsState({
    this.preferences,
    this.loading = true,
    this.saving = false,
    this.saved = false,
    this.error,
  });

  final AiPreferences? preferences;
  final bool loading;
  final bool saving;
  final bool saved;
  final String? error;

  bool get aiEnabled => preferences?.enabled ?? false;

  AutomationSettingsState copyWith({
    AiPreferences? preferences,
    bool? loading,
    bool? saving,
    bool? saved,
    String? error,
  }) =>
      AutomationSettingsState(
        preferences: preferences ?? this.preferences,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        saved: saved ?? this.saved,
        error: error,
      );

  @override
  List<Object?> get props => [preferences, loading, saving, saved, error];
}
