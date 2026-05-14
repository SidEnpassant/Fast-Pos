import 'package:inventopos/domain/entities/user_profile.dart';

/// Profile row stream for the signed-in user.
abstract class ProfileRepository {
  /// `null` when no user is signed in.
  Stream<List<UserProfile>>? watchProfileForCurrentUser();

  /// One-shot read for flows that are not stream-driven (e.g. PDF generation).
  Future<UserProfile?> fetchCurrentUserProfileSnapshot();

  /// Updates arbitrary `profiles` columns for [userId] (keys are DB column names).
  Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> columns,
  });

  /// Maps UI field keys (e.g. `businessName`) to storage columns and updates one field.
  Future<void> updateProfileFieldByLogicalKey({
    required String userId,
    required String fieldKey,
    required String value,
  });

  /// Uploads a new signature image and persists `signature_url` on `profiles`.
  Future<void> replaceSignatureFromLocalFile({
    required String userId,
    required String localFilePath,
  });
}
