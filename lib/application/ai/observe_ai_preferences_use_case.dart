import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';

class ObserveAiPreferencesUseCase {
  ObserveAiPreferencesUseCase(this._preferences);

  final AiPreferencesPort _preferences;

  Stream<AiPreferences> call(String userId) => _preferences.watch(userId);
}
