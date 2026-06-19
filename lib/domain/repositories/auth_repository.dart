import 'package:inventopos/domain/entities/auth_session.dart';

/// Authentication boundary (DIP). Implementation lives in `lib/data/`.
abstract class AuthRepository {
  Stream<AuthSession?> get sessionStream;

  AuthSession? get currentSession;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Native Google Sign-In → Supabase token exchange.
  Future<void> signInWithGoogle();

  Future<void> signOut();

  Future<void> resetPasswordForEmail(String email);
}
