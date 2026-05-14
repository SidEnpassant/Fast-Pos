import 'package:inventopos/domain/repositories/profile_repository.dart';

class ReplaceAccountSignatureUseCase {
  const ReplaceAccountSignatureUseCase(this._profiles);

  final ProfileRepository _profiles;

  Future<void> call({
    required String userId,
    required String localFilePath,
  }) =>
      _profiles.replaceSignatureFromLocalFile(
        userId: userId,
        localFilePath: localFilePath,
      );
}
