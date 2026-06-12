import 'package:inventopos/domain/ai/entities/ai_briefing.dart';

import 'package:inventopos/domain/ai/failures/ai_failure.dart';

abstract class AiGatewayPort {
  Future<AiResult<AiBriefing>> generateBriefing({
    required Map<String, dynamic> metrics,
  });

  Future<AiResult<String>> completePrompt({required String prompt});
}
