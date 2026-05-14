import 'package:inventopos/domain/registration/registration_payload.dart';
import 'package:inventopos/domain/registration/registration_result.dart';
import 'package:inventopos/domain/repositories/registration_repository.dart';

class RegisterAccountUseCase {
  const RegisterAccountUseCase(this._repository);

  final RegistrationRepository _repository;

  Future<RegistrationResult> call(RegistrationPayload payload) =>
      _repository.register(payload);
}
