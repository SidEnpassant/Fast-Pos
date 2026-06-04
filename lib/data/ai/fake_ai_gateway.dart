import 'package:inventopos/domain/ai/entities/ai_briefing.dart';
import 'package:inventopos/domain/ai/entities/billing_suggestion.dart';
import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';
import 'package:inventopos/domain/ai/repositories/ai_gateway_port.dart';

/// Test double for [AiGatewayPort].
class FakeAiGateway implements AiGatewayPort {
  FakeAiGateway({
    this.voiceResult,
    this.suggestions = const [],
    this.briefingMarkdown = 'Test briefing',
    this.shouldFail = false,
  });

  VoiceBillCommand? voiceResult;
  List<BillingSuggestion> suggestions;
  String briefingMarkdown;
  bool shouldFail;

  @override
  Future<AiResult<VoiceBillCommand>> parseVoiceBill({
    required String transcript,
    required String locale,
    required List<Map<String, String>> catalog,
  }) async {
    if (shouldFail) {
      return const AiError(
        AiFailure(code: AiFailureCode.serverError),
      );
    }
    return AiSuccess(
      voiceResult ??
          VoiceBillCommand(
            lines: [
              VoiceBillLine(
                productName: transcript.split(' ').first,
                quantity: 1,
              ),
            ],
          ),
    );
  }

  @override
  Future<AiResult<List<BillingSuggestion>>> suggestProducts({
    required String prefix,
    required List<String> basketProductIds,
    required List<Map<String, String>> catalog,
  }) async {
    if (shouldFail) {
      return const AiError(AiFailure(code: AiFailureCode.serverError));
    }
    return AiSuccess(suggestions);
  }

  @override
  Future<AiResult<AiBriefing>> generateBriefing({
    required Map<String, dynamic> metrics,
  }) async {
    if (shouldFail) {
      return const AiError(AiFailure(code: AiFailureCode.serverError));
    }
    return AiSuccess(AiBriefing(markdown: briefingMarkdown));
  }

  @override
  Future<AiResult<String>> completePrompt({required String prompt}) async {
    return AiSuccess('Answer to: $prompt');
  }
}
