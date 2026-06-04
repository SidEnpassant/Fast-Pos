import 'package:inventopos/domain/ai/entities/ai_briefing.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';
import 'package:inventopos/domain/ai/repositories/ai_gateway_port.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';
import 'package:inventopos/domain/automation/policies/automation_policy.dart';

class RunDailyBusinessBriefUseCase {
  RunDailyBusinessBriefUseCase(this._gateway, this._preferences);

  final AiGatewayPort _gateway;
  final AiPreferencesPort _preferences;

  Future<AiResult<AiBriefing>> call({
    required String userId,
    required Map<String, dynamic> metrics,
  }) async {
    final prefs = await _preferences.fetch(userId);
    if (!AutomationPolicy.canRunDailyBrief(prefs)) {
      return const AiError(
        AiFailure(
          code: AiFailureCode.consentDenied,
          message: 'Daily brief is disabled.',
        ),
      );
    }
    return _gateway.generateBriefing(metrics: metrics);
  }
}
