import 'package:inventopos/domain/repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  const UpdatePasswordUseCase(this._auth);

  final AuthRepository _auth;

  Future<void> call(String newPassword) => _auth.updatePassword(newPassword);
}
