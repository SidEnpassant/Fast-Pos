import 'package:inventopos/domain/repositories/profile_repository.dart';

class PatchAccountProfileFieldUseCase {
  const PatchAccountProfileFieldUseCase(this._profiles);

  final ProfileRepository _profiles;

  Future<void> call({
    required String userId,
    required String fieldKey,
    required String value,
  }) =>
      _profiles.updateProfileFieldByLogicalKey(
        userId: userId,
        fieldKey: fieldKey,
        value: value,
      );
}
