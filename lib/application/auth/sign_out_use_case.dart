import 'package:inventopos/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() => _authRepository.signOut();
}
