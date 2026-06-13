import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/presentation/auth/widgets/auth_glass_card.dart';
import 'package:inventopos/presentation/auth/widgets/auth_scaffold.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_event.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_state.dart';
import 'package:inventopos/presentation/auth_login/widgets/login_credentials_fields.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/presentation/auth_login/widgets/login_register_prompt.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
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
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<LoginBloc>().add(const LoginUiMessageConsumed());
        }
      },
      builder: (context, state) {
        final videoPeek = MediaQuery.sizeOf(context).height * 0.22;
        return AuthScaffold(
          topContentSpacing: videoPeek,
          title: 'Welcome back',
          subtitle: 'Sign in to manage sales, stock, and bills',
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: AuthGlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LoginCredentialsFields(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: state.obscurePassword,
                      onToggleObscure: () => context
                          .read<LoginBloc>()
                          .add(const LoginObscurePasswordToggled()),
                      onSubmit: _submit,
                      emailError: state.emailError,
                      passwordError: state.passwordError,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: state.isSubmitting ? null : _submit,
                      child: state.isSubmitting
                          ? const AppShimmer(
                              child: Text('Sign in'),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 8),
                    const LoginRegisterPrompt(),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'FastPOS helps you bill faster, track stock, and grow with real analytics.',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
