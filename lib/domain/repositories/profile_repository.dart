/// Profile row stream for the signed-in user.
abstract class ProfileRepository {
  /// `null` when no user is signed in.
  Stream<List<Map<String, dynamic>>>? watchProfileForCurrentUser();
}
