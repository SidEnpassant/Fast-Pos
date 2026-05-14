import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/auth/sign_in_use_case.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  test('SignInUseCase forwards to repository', () async {
    final repo = _MockAuthRepo();
    when(
      () => repo.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    final useCase = SignInUseCase(repo);
    await useCase(email: 'a@b.com', password: 'secret');

    verify(
      () => repo.signInWithPassword(email: 'a@b.com', password: 'secret'),
    ).called(1);
  });
}
