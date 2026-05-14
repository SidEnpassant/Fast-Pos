import 'package:inventopos/domain/repositories/auth_repository.dart';

/// Sends Supabase password recovery email for [email].
class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._auth);

  final AuthRepository _auth;

  Future<void> call(String email) => _auth.resetPasswordForEmail(email);
}
