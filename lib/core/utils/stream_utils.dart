import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

/// Hive [Box.watch] only emits on mutations — this also emits [read] immediately.
Stream<T> hiveWatchStream<T>({
  required Stream<BoxEvent> events,
  required T Function() read,
  bool Function(BoxEvent)? filter,
}) {
  return Stream.multi((controller) {
    controller.add(read());
    final sub = events
        .where((e) => filter == null || filter(e))
        .map((_) => read())
        .listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
    controller.onCancel = () => sub.cancel();
  });
}

/// Replays [cache] to new listeners, then forwards [live] updates.
Stream<T> replayStream<T>(Stream<T> live, T? cache) {
  if (cache == null) return live;
  return Stream.multi((controller) {
    controller.add(cache);
    final sub = live.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = () => sub.cancel();
  });
}
