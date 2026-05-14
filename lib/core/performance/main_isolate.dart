import 'dart:async';

/// Defers heavy synchronous work so the current frame can finish first.
/// Use for PDF/OCR prep after navigation; prefer real isolates for large CPU work.
Future<void> deferToNextEventLoop(FutureOr<void> Function() work) {
  return Future<void>(() async {}).then((_) => work());
}
