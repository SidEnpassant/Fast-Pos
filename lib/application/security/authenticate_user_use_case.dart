import 'package:local_auth/local_auth.dart';

class AuthenticateUserUseCase {
  AuthenticateUserUseCase({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> call({String reason = 'Authenticate to continue'}) async {
    final can = await _auth.canCheckBiometrics;
    if (!can) return true;
    return _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(biometricOnly: false),
    );
  }
}
