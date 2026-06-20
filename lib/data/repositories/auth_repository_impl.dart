import 'package:google_sign_in/google_sign_in.dart';
import 'package:inventopos/domain/auth/auth_operation_failure.dart';
import 'package:inventopos/domain/entities/auth_session.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  AuthSession? _mapSession(Session? session) {
    if (session == null) return null;
    final user = session.user;
    return AuthSession(userId: user.id, email: user.email);
  }

  @override
  Stream<AuthSession?> get sessionStream =>
      _client.auth.onAuthStateChange.map((event) => _mapSession(event.session));

  @override
  AuthSession? get currentSession => _mapSession(_client.auth.currentSession);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthOperationFailure(e.message);
    }
  }

  @override
  Future<void> signInWithGoogle() async {

    const webClientId =
        'MY_WEB_CLIENT_ID.apps.googleusercontent.com'; 

    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthOperationFailure('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw AuthOperationFailure(
        'Could not retrieve Google ID token. Ensure your OAuth client is configured.',
      );
    }


    try {
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthException catch (e) {
      throw AuthOperationFailure(e.message);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthOperationFailure(e.message);
    }
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: OtpType.recovery,
      );
    } on AuthException catch (e) {
      throw AuthOperationFailure(e.message);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw AuthOperationFailure(e.message);
    }
  }
}
