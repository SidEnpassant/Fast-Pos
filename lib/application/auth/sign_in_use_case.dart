import 'package:inventopos/domain/repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call({
    required String email,
    required String password,
  }) {
    return _authRepository.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
