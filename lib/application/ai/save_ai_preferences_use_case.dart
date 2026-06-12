import 'package:inventopos/application/automation/sync_automation_jobs_from_prefs_use_case.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';

class SaveAiPreferencesUseCase {
  SaveAiPreferencesUseCase(
    this._preferences,
    this._syncJobs,
  );

  final AiPreferencesPort _preferences;
  final SyncAutomationJobsFromPrefsUseCase _syncJobs;

  Future<void> call(AiPreferences preferences) async {
    await _preferences.save(preferences);
    if (preferences.enabled) {
      await _syncJobs(preferences);
    }
  }
}
