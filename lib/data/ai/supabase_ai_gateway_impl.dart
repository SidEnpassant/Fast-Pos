import 'package:inventopos/data/ai/edge_function_client.dart';
import 'package:inventopos/domain/ai/entities/ai_briefing.dart';
import 'package:inventopos/domain/ai/entities/ai_insight.dart';
import 'package:inventopos/domain/ai/entities/billing_suggestion.dart';
import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';
import 'package:inventopos/domain/ai/repositories/ai_gateway_port.dart';

class SupabaseAiGatewayImpl implements AiGatewayPort {
  SupabaseAiGatewayImpl(this._client);

  final EdgeFunctionClient _client;

  @override
  Future<AiResult<VoiceBillCommand>> parseVoiceBill({
    required String transcript,
    required String locale,
    required List<Map<String, String>> catalog,
  }) async {
    try {
      final data = await _client.invoke('ai-voice-parse', body: {
        'transcript': transcript,
        'locale': locale,
        'catalog': catalog,
      });
      if (data['error'] != null) {
        return AiError(_mapError(data['error'].toString()));
      }
      final lines = (data['lines'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map(
            (e) => VoiceBillLine(
              productName: e['product_name']?.toString() ?? '',
              quantity: (e['quantity'] as num?)?.toInt() ?? 1,
              productId: e['product_id']?.toString(),
            ),
          )
          .toList();
      return AiSuccess(
        VoiceBillCommand(
          customerHint: data['customer_hint']?.toString(),
          lines: lines,
        ),
      );
    } on EdgeFunctionException catch (e) {
      return AiError(_fromEdge(e));
    } catch (e) {
      return AiError(_offlineOrUnknown(e));
    }
  }

  @override
  Future<AiResult<List<BillingSuggestion>>> suggestProducts({
    required String prefix,
    required List<String> basketProductIds,
    required List<Map<String, String>> catalog,
  }) async {
    try {
      final data = await _client.invoke('ai-suggest-products', body: {
        'prefix': prefix,
        'basket_product_ids': basketProductIds,
        'catalog': catalog,
      });
      final list = (data['suggestions'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map(
            (e) => BillingSuggestion(
              productId: e['product_id']?.toString() ?? '',
              reason: e['reason']?.toString() ?? '',
            ),
          )
          .where((s) => s.productId.isNotEmpty)
          .toList();
      return AiSuccess(list);
    } on EdgeFunctionException catch (e) {
      return AiError(_fromEdge(e));
    } catch (e) {
      return AiError(_offlineOrUnknown(e));
    }
  }

  @override
  Future<AiResult<AiBriefing>> generateBriefing({
    required Map<String, dynamic> metrics,
  }) async {
    try {
      final data = await _client.invoke('ai-briefing', body: {'metrics': metrics});
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
      final data = await _client.invoke('ai-complete', body: {'prompt': prompt});
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

  AiFailure _mapError(String msg) =>
      AiFailure(code: AiFailureCode.parseError, message: msg);

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
