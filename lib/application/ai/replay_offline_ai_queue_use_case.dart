import 'package:inventopos/data/ai/ai_request_queue.dart';
import 'package:inventopos/data/ai/edge_function_client.dart';

class ReplayOfflineAiQueueUseCase {
  ReplayOfflineAiQueueUseCase(this._queue, this._client);

  final AiRequestQueue _queue;
  final EdgeFunctionClient _client;

  Future<int> call(String userId) async {
    final pending = await _queue.pendingFor(userId);
    var replayed = 0;
    for (final req in pending) {
      try {
        await _client.invoke(req.functionName, body: req.body);
        await _queue.remove(req.id);
        replayed++;
      } catch (_) {}
    }
    return replayed;
  }
}
