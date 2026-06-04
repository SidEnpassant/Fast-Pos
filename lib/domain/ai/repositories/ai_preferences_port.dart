import 'package:inventopos/domain/ai/entities/ai_preferences.dart';

abstract class AiPreferencesPort {
  Future<AiPreferences> fetch(String userId);

  Future<void> save(AiPreferences preferences);

  Stream<AiPreferences> watch(String userId);
}
