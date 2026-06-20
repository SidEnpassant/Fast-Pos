import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/presentation/auth/widgets/auth_glass_card.dart';
import 'package:inventopos/presentation/auth/widgets/auth_scaffold.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_event.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_state.dart';
import 'package:inventopos/presentation/auth_login/widgets/login_credentials_fields.dart';
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
        return AuthScaffold(
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
                        child: const Text('Login with Otp'),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.25),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: const Color.fromARGB(137, 0, 0, 0),
                                      letterSpacing: 1.2,
                                    ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      // onPressed: state.isGoogleSigningIn
                      //     ? null
                      //     : () => context
                      //         .read<LoginBloc>()
                      //         .add(const LoginGoogleSignInRequested()),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: const Row(
                              children: [
                                Icon(Icons.rocket_launch_rounded),
                                SizedBox(width: 8),
                                Text('Coming Soon'),
                              ],
                            ),
                            content: const Text(
                              'Google Sign-In is currently under development and will be available in an upcoming update.\n\nThank you for your patience!',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      icon: state.isGoogleSigningIn
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Image.asset(
                              'assets/images/google_logo.png',
                              width: 40,
                              height: 40,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.g_mobiledata, size: 22),
                            ),
                      label: Text(
                        state.isGoogleSigningIn
                            ? 'Signing in…'
                            : 'Sign in with Google',
                      ),
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
