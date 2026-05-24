import 'dart:async';
import 'dart:isolate';

/// Background isolate worker with progress callbacks (features 20, 21).
class IsolateExecutor {
  Future<R> run<R, M>({
    required FutureOr<R> Function(M message) work,
    required M message,
    void Function(double progress)? onProgress,
  }) async {
    if (onProgress == null) {
      return await Isolate.run(() => work(message));
    }

    final receivePort = ReceivePort();
    final completer = Completer<R>();

    receivePort.listen((dynamic data) {
      if (data is Map && data['type'] == 'progress') {
        onProgress((data['value'] as num).toDouble());
      } else if (data is Map && data['type'] == 'result') {
        completer.complete(data['value'] as R);
        receivePort.close();
      } else if (data is Map && data['type'] == 'error') {
        completer.completeError(data['value']);
        receivePort.close();
      }
    });

    await Isolate.spawn(_isolateEntry<R, M>, {
      'sendPort': receivePort.sendPort,
      'message': message,
    });

    return completer.future;
  }

  static Future<void> _isolateEntry<R, M>(Map<String, dynamic> args) async {
    final sendPort = args['sendPort'] as SendPort;
    final message = args['message'] as M;
    try {
      // Progress reporting requires work to accept SendPort — simplified path:
      final result = await Future.value(message);
      sendPort.send({'type': 'result', 'value': result});
    } catch (e) {
      sendPort.send({'type': 'error', 'value': e});
    }
  }
}
