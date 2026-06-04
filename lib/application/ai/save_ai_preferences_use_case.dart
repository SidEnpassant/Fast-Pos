import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';
import 'package:inventopos/domain/automation/repositories/automation_job_port.dart';

class SaveAiPreferencesUseCase {
  SaveAiPreferencesUseCase(this._preferences, this._jobs);

  final AiPreferencesPort _preferences;
  final AutomationJobPort _jobs;

  Future<void> call(AiPreferences preferences) async {
    await _preferences.save(preferences);
    if (preferences.enabled) {
      await _jobs.ensureDefaults(preferences.userId);
    }
  }
}
