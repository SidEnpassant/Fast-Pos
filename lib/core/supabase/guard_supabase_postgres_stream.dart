import 'dart:async';

import 'package:flutter/foundation.dart';

/// Wraps Supabase Postgres `.stream()` chains so realtime / PostgREST failures
/// delivered through [Stream.addError] do not become **uncaught async errors**
/// when consumers use [Stream.listen] without `onError` (common with Bloc).
///
/// See `SupabaseStreamBuilder._addException` in the `supabase` package.
Stream<T> guardSupabasePostgresStream<T>(Stream<T> source) {
  return source.handleError(
    (Object error, StackTrace stackTrace) {
      if (kDebugMode) {
        debugPrint('Supabase postgres stream error (handled): $error');
      }
    },
  );
}
