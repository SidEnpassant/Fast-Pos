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
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthOperationFailure(e.message);
    }
  }
}
