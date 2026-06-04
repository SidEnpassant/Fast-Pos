import 'package:inventopos/domain/ai/entities/ai_briefing.dart';
import 'package:inventopos/domain/ai/entities/billing_suggestion.dart';
import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';

abstract class AiGatewayPort {
  Future<AiResult<VoiceBillCommand>> parseVoiceBill({
    required String transcript,
    required String locale,
    required List<Map<String, String>> catalog,
  });

  Future<AiResult<List<BillingSuggestion>>> suggestProducts({
    required String prefix,
    required List<String> basketProductIds,
    required List<Map<String, String>> catalog,
  });

  Future<AiResult<AiBriefing>> generateBriefing({
    required Map<String, dynamic> metrics,
  });

  Future<AiResult<String>> completePrompt({required String prompt});
}
