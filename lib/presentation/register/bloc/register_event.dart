import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/registration/registration_payload.dart';

sealed class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

final class RegisterPasswordVisibilityToggled extends RegisterEvent {
  const RegisterPasswordVisibilityToggled();
}

final class RegisterSignaturePathChanged extends RegisterEvent {
  const RegisterSignaturePathChanged(this.path);

  final String? path;

  @override
  List<Object?> get props => [path];
}

final class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted(this.payload);

  final RegistrationPayload payload;

  @override
  List<Object?> get props => [payload];
}
