import 'package:inventopos/domain/entities/user_profile.dart';

/// Profile row stream for the signed-in user.
abstract class ProfileRepository {
  /// `null` when no user is signed in.
  Stream<List<UserProfile>>? watchProfileForCurrentUser();

  /// One-shot read for flows that are not stream-driven (e.g. PDF generation).
  Future<UserProfile?> fetchCurrentUserProfileSnapshot();
}
