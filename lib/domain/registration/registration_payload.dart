import 'package:equatable/equatable.dart';

/// Immutable registration form data passed from presentation to application layer.
class RegistrationPayload extends Equatable {
  const RegistrationPayload({
    required this.fullName,
    required this.businessName,
    required this.businessAddress,
    required this.phone,
    required this.email,
    required this.password,
    required this.gstNumber,
    required this.billRules,
    required this.signatureLocalPath,
  });

  final String fullName;
  final String businessName;
  final String businessAddress;
  final String phone;
  final String email;
  final String password;
  final String gstNumber;
  final String billRules;
  final String signatureLocalPath;

  @override
  List<Object?> get props => [
        fullName,
        businessName,
        businessAddress,
        phone,
        email,
        password,
        gstNumber,
        billRules,
        signatureLocalPath,
      ];
}
