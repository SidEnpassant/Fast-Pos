import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<Session?> get sessionStream =>
      _client.auth.onAuthStateChange.map((event) => event.session);

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> resetPasswordForEmail(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());
}
