import 'package:inventopos/domain/repositories/auth_repository.dart';

class VerifyRecoveryOtpUseCase {
  const VerifyRecoveryOtpUseCase(this._auth);

  final AuthRepository _auth;

  Future<void> call({required String email, required String otp}) =>
      _auth.verifyRecoveryOtp(email: email, otp: otp);
}
