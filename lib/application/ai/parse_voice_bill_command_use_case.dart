import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';
import 'package:inventopos/domain/ai/repositories/ai_gateway_port.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';
import 'package:inventopos/data/ai/ai_request_queue.dart';
import 'package:inventopos/domain/automation/policies/automation_policy.dart';
import 'package:inventopos/domain/entities/product.dart';

class ParseVoiceBillCommandUseCase {
  ParseVoiceBillCommandUseCase(
    this._gateway,
    this._preferences, [
    this._queue,
  ]);

  final AiGatewayPort _gateway;
  final AiPreferencesPort _preferences;
  final AiRequestQueue? _queue;

  Future<AiResult<VoiceBillCommand>> call({
    required String userId,
    required String transcript,
    required List<Product> products,
  }) async {
    final prefs = await _preferences.fetch(userId);
    if (!AutomationPolicy.canInvokeCloudAi(prefs)) {
      return const AiError(
        AiFailure(
          code: AiFailureCode.consentDenied,
          message: 'Enable Smart Assistant in settings first.',
        ),
      );
    }
    final catalog = _catalogFrom(products, prefs);
    final result = await _gateway.parseVoiceBill(
      transcript: transcript,
      locale: prefs.language,
      catalog: catalog,
    );
    if (result case AiError(:final failure) when _queue != null) {
      if (failure.code == AiFailureCode.offline ||
          failure.code == AiFailureCode.serverError) {
        await _queue.enqueue(
          userId: userId,
          functionName: 'ai-voice-parse',
          body: {
            'transcript': transcript,
            'locale': prefs.language,
            'catalog': catalog,
          },
        );
      }
    }
    return result;
  }

  List<Map<String, String>> _catalogFrom(
    List<Product> products,
    AiPreferences prefs,
  ) {
    final active = products.where((p) => p.isActive).take(200);
    return active
        .map(
          (p) => {
            'id': p.id,
            'name': p.name,
            if (prefs.enhancedContext && p.barcode != null)
              'barcode': p.barcode!,
          },
        )
        .toList();
  }
}
