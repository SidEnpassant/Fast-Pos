import 'package:inventopos/data/ai/edge_function_client.dart';
import 'package:inventopos/domain/ai/entities/ai_briefing.dart';
import 'package:inventopos/domain/ai/entities/ai_insight.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';
import 'package:inventopos/domain/ai/repositories/ai_gateway_port.dart';

class SupabaseAiGatewayImpl implements AiGatewayPort {
  SupabaseAiGatewayImpl(this._client);

  final EdgeFunctionClient _client;

  @override
  Future<AiResult<AiBriefing>> generateBriefing({
    required Map<String, dynamic> metrics,
  }) async {
    try {
      final data =
          await _client.invoke('ai-briefing', body: {'metrics': metrics});
      final insights = (data['insights'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map(
            (e) => AiInsight(
              id: '',
              type: e['type']?.toString() ?? 'general',
              title: e['title']?.toString() ?? '',
              body: e['body']?.toString() ?? '',
              dedupKey: '',
              createdAt: DateTime.now(),
            ),
          )
          .toList();
      return AiSuccess(
        AiBriefing(
          markdown: data['markdown']?.toString() ?? '',
          insights: insights,
        ),
      );
    } on EdgeFunctionException catch (e) {
      return AiError(_fromEdge(e));
    } catch (e) {
      return AiError(_offlineOrUnknown(e));
    }
  }

  @override
  Future<AiResult<String>> completePrompt({required String prompt}) async {
    try {
      final data =
          await _client.invoke('ai-complete', body: {'prompt': prompt});
      return AiSuccess(data['answer']?.toString() ?? '');
    } on EdgeFunctionException catch (e) {
      return AiError(_fromEdge(e));
    } catch (e) {
      return AiError(AiFailure(code: AiFailureCode.unknown, message: '$e'));
    }
  }

  AiFailure _fromEdge(EdgeFunctionException e) {
    if (e.isRateLimited) {
      return const AiFailure(
        code: AiFailureCode.rateLimited,
        message: 'AI is busy. Try again in a moment.',
      );
    }
    return AiFailure(code: AiFailureCode.serverError, message: e.message);
  }

  AiFailure _offlineOrUnknown(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('failed host')) {
      return const AiFailure(
        code: AiFailureCode.offline,
        message: 'No connection. Request queued for later.',
      );
    }
    return AiFailure(code: AiFailureCode.unknown, message: '$e');
  }
}
