import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication boundary (DIP). Implementation lives in `lib/data/`.
abstract class AuthRepository {
  Stream<Session?> get sessionStream;

  Session? get currentSession;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> resetPasswordForEmail(String email);
}
