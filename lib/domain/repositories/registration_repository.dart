import 'package:inventopos/domain/registration/registration_payload.dart';
import 'package:inventopos/domain/registration/registration_result.dart';

/// Sign-up plus initial profile row and signature upload (Supabase-backed).
abstract class RegistrationRepository {
  Future<RegistrationResult> register(RegistrationPayload payload);
}
