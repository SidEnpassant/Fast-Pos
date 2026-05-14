import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_event.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_state.dart';
import 'package:inventopos/presentation/auth_login/widgets/login_branding_header.dart';
import 'package:inventopos/presentation/auth_login/widgets/login_credentials_fields.dart';
import 'package:inventopos/presentation/auth_login/widgets/login_register_prompt.dart';
import 'package:inventopos/presentation/auth_login/widgets/login_submit_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<LoginBloc>().add(
          LoginSubmitted(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (p, c) =>
          c.errorMessage != null && c.errorMessage != p.errorMessage,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          context.read<LoginBloc>().add(const LoginUiMessageConsumed());
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoginBrandingHeader(),
                  LoginCredentialsFields(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: state.obscurePassword,
                    onToggleObscure: () => context
                        .read<LoginBloc>()
                        .add(const LoginObscurePasswordToggled()),
                    emailError: state.emailError,
                    passwordError: state.passwordError,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LoginSubmitButton(
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                  const LoginRegisterPrompt(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
