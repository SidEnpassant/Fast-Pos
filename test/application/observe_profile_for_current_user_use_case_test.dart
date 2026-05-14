import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  test('returns repository stream', () {
    final repo = _MockProfileRepository();
    final stream = Stream<List<UserProfile>>.value(const []);
    when(() => repo.watchProfileForCurrentUser()).thenAnswer((_) => stream);

    final useCase = ObserveProfileForCurrentUserUseCase(repo);
    expect(useCase(), same(stream));
    verify(() => repo.watchProfileForCurrentUser()).called(1);
  });

  test('returns null when repository returns null', () {
    final repo = _MockProfileRepository();
    when(() => repo.watchProfileForCurrentUser()).thenAnswer((_) => null);

    final useCase = ObserveProfileForCurrentUserUseCase(repo);
    expect(useCase(), isNull);
  });
}
