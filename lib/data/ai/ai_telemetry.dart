import 'package:supabase_flutter/supabase_flutter.dart';

/// Records AI call latency and success (client-side observability).
class AiTelemetry {
  AiTelemetry({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> recordSuccess({
    required String feature,
    required int latencyMs,
    int tokenEstimate = 100,
  }) async {
    try {
      await _client.rpc('increment_ai_usage', params: {
        'p_tokens': tokenEstimate,
      });
    } catch (_) {}
  }

  Future<void> recordFailure({
    required String feature,
    required String errorCode,
  }) async {
    // Reserved for future ai_telemetry table
  }
}
