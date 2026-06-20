import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/presentation/auth/widgets/auth_glass_card.dart';
import 'package:inventopos/presentation/auth/widgets/auth_scaffold.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_event.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_state.dart';
import 'package:pinput/pinput.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailFormKey = GlobalKey<FormState>();
  final _newPasswordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    if (!_emailFormKey.currentState!.validate()) return;
    context.read<ForgotPasswordBloc>().add(
          ForgotPasswordSubmitted(_emailController.text),
        );
  }

  void _submitOtp() {
    if (_otpController.text.length < 6) return;
    context.read<ForgotPasswordBloc>().add(
          ForgotPasswordOtpSubmitted(_otpController.text),
        );
  }

  void _submitNewPassword() {
    if (!_newPasswordFormKey.currentState!.validate()) return;
    context.read<ForgotPasswordBloc>().add(
          ForgotPasswordNewPasswordSubmitted(_newPasswordController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (p, c) =>
          c.errorMessage != null && c.errorMessage != p.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context
              .read<ForgotPasswordBloc>()
              .add(const ForgotPasswordUiCleared());
        }
        if (state.step == ForgotPasswordStep.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password successfully updated! Please log in.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      },
      builder: (context, state) {
        final loading = state.status == ForgotPasswordStatus.loading;

        String title = 'Login With Otp';
        String subtitle = 'Enter your email to receive an OTP';

        if (state.step == ForgotPasswordStep.otp) {
          title = 'Verify OTP and Login';
          subtitle = 'Enter the 6-digit code sent to ${state.email}';
        } else if (state.step == ForgotPasswordStep.newPassword) {
          title = 'New Password';
          subtitle = 'Enter your new secure password';
        } else if (state.step == ForgotPasswordStep.success) {
          title = 'Password Updated';
          subtitle = 'Your password has been reset successfully';
        }

        return AuthScaffold(
          title: title,
          subtitle: subtitle,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: AuthGlassCard(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(context, state, loading),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ForgotPasswordState state,
    bool loading,
  ) {
    switch (state.step) {
      case ForgotPasswordStep.email:
        return _buildEmailStep(context, loading);
      case ForgotPasswordStep.otp:
        return _buildOtpStep(context, loading);
      case ForgotPasswordStep.newPassword:
        // return _buildNewPasswordStep(context, loading);
        return Container();
      case ForgotPasswordStep.success:
        return _buildSuccessStep(context);
    }
  }

  Widget _buildEmailStep(BuildContext context, bool loading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        key: const ValueKey('email_step'),
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading ? null : _submitEmail,
            child: loading
                ? const AppShimmer(child: Text('Sending OTP...'))
                : const Text('Send OTP'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(BuildContext context, bool loading) {
    final theme = Theme.of(context);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const ValueKey('otp_step'),
      children: [
        Pinput(
          length: 6,
          controller: _otpController,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration?.copyWith(
              border: Border.all(color: theme.colorScheme.primary),
            ),
          ),
          onCompleted: (_) {
            if (!loading) _submitOtp();
          },
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: loading ? null : _submitOtp,
          child: loading
              ? const AppShimmer(child: Text('Verifying...'))
              : const Text('Verify OTP and Login'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: loading
              ? null
              : () => context
                  .read<ForgotPasswordBloc>()
                  .add(const ForgotPasswordBackRequested()),
          child: const Text('Change Email'),
        ),
      ],
    );
  }

  // Widget _buildNewPasswordStep(BuildContext context, bool loading) {
  //   return Form(
  //     key: _newPasswordFormKey,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       key: const ValueKey('new_password_step'),
  //       children: [
  //         TextFormField(
  //           controller: _newPasswordController,
  //           obscureText: _obscurePassword,
  //           textInputAction: TextInputAction.next,
  //           decoration: InputDecoration(
  //             labelText: 'New Password',
  //             prefixIcon: const Icon(Icons.lock_outline),
  //             suffixIcon: IconButton(
  //               icon: Icon(
  //                 _obscurePassword ? Icons.visibility_off : Icons.visibility,
  //               ),
  //               onPressed: () {
  //                 setState(() {
  //                   _obscurePassword = !_obscurePassword;
  //                 });
  //               },
  //             ),
  //           ),
  //           validator: (value) {
  //             if (value == null || value.length < 6) {
  //               return 'Password must be at least 6 characters';
  //             }
  //             return null;
  //           },
  //         ),
  //         const SizedBox(height: 16),
  //         TextFormField(
  //           controller: _confirmPasswordController,
  //           obscureText: _obscureConfirmPassword,
  //           textInputAction: TextInputAction.done,
  //           decoration: InputDecoration(
  //             labelText: 'Re-enter New Password',
  //             prefixIcon: const Icon(Icons.lock_outline),
  //             suffixIcon: IconButton(
  //               icon: Icon(
  //                 _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
  //               ),
  //               onPressed: () {
  //                 setState(() {
  //                   _obscureConfirmPassword = !_obscureConfirmPassword;
  //                 });
  //               },
  //             ),
  //           ),
  //           validator: (value) {
  //             if (value != _newPasswordController.text) {
  //               return 'Passwords do not match';
  //             }
  //             return null;
  //           },
  //         ),
  //         const SizedBox(height: 24),
  //         FilledButton(
  //           onPressed: loading ? null : _submitNewPassword,
  //           child: loading
  //               ? const AppShimmer(child: Text('Updating...'))
  //               : const Text('Update Password'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSuccessStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const ValueKey('success_step'),
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 80,
        ),
        const SizedBox(height: 16),
        Text(
          'Your password has been successfully reset. You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Go to Login'),
        ),
      ],
    );
  }
}
