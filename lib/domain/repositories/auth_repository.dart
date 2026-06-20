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

  /// Verify a 6-digit OTP sent to the user's email for password recovery.
  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  });

  /// Update the user's password (must be called after verifying recovery OTP).
  Future<void> updatePassword(String newPassword);
}
