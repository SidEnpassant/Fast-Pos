import 'dart:io';

import 'package:inventopos/domain/registration/registration_payload.dart';
import 'package:inventopos/domain/registration/registration_result.dart';
import 'package:inventopos/domain/repositories/registration_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationRepositoryImpl implements RegistrationRepository {
  RegistrationRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<RegistrationResult> register(RegistrationPayload payload) async {
    try {
      final currentUser = _client.auth.currentUser;
      final User? user;
      
      if (currentUser != null && currentUser.email == payload.email.trim()) {
        final authRes = await _client.auth.updateUser(
          UserAttributes(
            password: payload.password,
            data: {'profile_completed': true},
          ),
        );
        user = authRes.user;
      } else {
        final authRes = await _client.auth.signUp(
          email: payload.email.trim(),
          password: payload.password,
          data: {'profile_completed': true},
        );
        user = authRes.user;
        if (authRes.session == null) {
          return RegistrationResult.rejectedNoSession();
        }
      }

      if (user == null) {
        return RegistrationResult.rejectedInvalid(
          'Sign up was rejected. Check the email format, password strength, '
          'and that your Supabase anon key is the JWT from Project Settings → API (starts with eyJ).',
        );
      }

      final signatureUrl =
          await _uploadSignature(user.id, payload.signatureLocalPath);

      await _client.from('profiles').upsert({
        'id': user.id,
        'email': payload.email.trim(),
        'name': payload.fullName,
        'business_name': payload.businessName,
        'business_address': payload.businessAddress,
        'phone_number': payload.phone,
        'gst_number': payload.gstNumber.trim(),
        'bill_rules': payload.billRules.trim(),
        'signature_url': signatureUrl,
      }, onConflict: 'id');

      return RegistrationResult.success();
    } on AuthException catch (e) {
      var errorMessage = e.message.trim();
      if (errorMessage.isEmpty) {
        errorMessage = 'Sign up failed (auth). Check API keys and network.';
      }
      final lower = errorMessage.toLowerCase();
      if (lower.contains('already registered') ||
          lower.contains('user already') ||
          lower.contains('already been registered')) {
        errorMessage = 'This email is already registered';
      }
      return RegistrationResult.failure(errorMessage);
    } catch (e) {
      final msg = e.toString();
      return RegistrationResult.failure(
        msg.length > 300 ? '${msg.substring(0, 300)}…' : msg,
      );
    }
  }

  Future<String> _uploadSignature(String userId, String localPath) async {
    final path = '$userId/signature.jpg';
    final file = File(localPath);
    await _client.storage.from('signatures').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('signatures').getPublicUrl(path);
  }
}
