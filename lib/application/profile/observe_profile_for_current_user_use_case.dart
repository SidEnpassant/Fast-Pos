import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';

class ObserveProfileForCurrentUserUseCase {
  const ObserveProfileForCurrentUserUseCase(this._repository);

  final ProfileRepository _repository;

  Stream<List<UserProfile>>? call() {
    return _repository.watchProfileForCurrentUser();
  }
}
