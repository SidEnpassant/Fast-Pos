import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/auth/sign_in_use_case.dart';
import 'package:inventopos/domain/auth/auth_operation_failure.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_event.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;

  setUp(() {
    repo = _MockAuthRepo();
  });

  blocTest<LoginBloc, LoginState>(
    'toggle obscure password',
    build: () => LoginBloc(SignInUseCase(repo)),
    act: (b) => b.add(const LoginObscurePasswordToggled()),
    expect: () => [const LoginState(obscurePassword: false)],
  );

  blocTest<LoginBloc, LoginState>(
    'submit with invalid email sets emailError',
    build: () => LoginBloc(SignInUseCase(repo)),
    act: (b) => b.add(
      const LoginSubmitted(email: 'bad', password: 'secret'),
    ),
    expect: () => [
      const LoginState(emailError: 'Please enter a valid email'),
    ],
    verify: (_) {
      verifyNever(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  blocTest<LoginBloc, LoginState>(
    'successful submit clears submitting',
    build: () {
      when(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      return LoginBloc(SignInUseCase(repo));
    },
    act: (b) => b.add(
      const LoginSubmitted(email: 'a@b.com', password: 'secret'),
    ),
    expect: () => [
      const LoginState(isSubmitting: true),
      const LoginState(isSubmitting: false),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'failed submit sets errorMessage',
    build: () {
      when(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(AuthOperationFailure('Invalid login credentials'));
      return LoginBloc(SignInUseCase(repo));
    },
    act: (b) => b.add(
      const LoginSubmitted(email: 'a@b.com', password: 'wrong'),
    ),
    expect: () => [
      const LoginState(isSubmitting: true),
      const LoginState(
        isSubmitting: false,
        errorMessage: 'Wrong email or password',
      ),
    ],
  );
}
