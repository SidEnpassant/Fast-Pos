import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed invoke wrapper for Supabase Edge Functions.
class EdgeFunctionClient {
  EdgeFunctionClient({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> invoke(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: body ?? {},
    );
    if (response.status >= 400) {
      throw EdgeFunctionException(
        status: response.status,
        message: response.data?.toString() ?? 'Edge function error',
      );
    }
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }
}

class EdgeFunctionException implements Exception {
  EdgeFunctionException({required this.status, required this.message});
  final int status;
  final String message;

  bool get isRateLimited => status == 429;

  @override
  String toString() => 'EdgeFunctionException($status): $message';
}
