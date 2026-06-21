import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/domain/registration/registration_payload.dart';
import 'package:inventopos/presentation/auth/widgets/auth_glass_card.dart';
import 'package:inventopos/presentation/auth/widgets/auth_scaffold.dart';
import 'package:inventopos/presentation/auth/widgets/auth_step_progress_bar.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_event.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_event.dart';
import 'package:inventopos/presentation/daybook/bloc/daybook_bloc.dart';
import 'package:inventopos/presentation/loyalty/bloc/loyalty_bloc.dart';
import 'package:inventopos/presentation/loyalty/bloc/loyalty_event.dart';
import 'package:inventopos/presentation/stock_audit/bloc/stock_audit_bloc.dart';
import 'package:inventopos/presentation/register/bloc/register_bloc.dart';
import 'package:inventopos/presentation/register/bloc/register_event.dart';
import 'package:inventopos/presentation/register/bloc/register_state.dart';
import 'package:inventopos/presentation/register/widgets/register_step_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _stepLabels = ['Personal', 'Business', 'Billing'];

  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gstController = TextEditingController();
  final _billRulesController = TextEditingController();
  final _picker = ImagePicker();

  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _gstController.dispose();
    _billRulesController.dispose();
    super.dispose();
  }

  Future<void> _pickSignature() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;
    context.read<RegisterBloc>().add(
          RegisterSignaturePathChanged(image.path),
        );
  }

  void _showStepError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showStepError('Enter your full name');
          return false;
        }
        if (_phoneController.text.trim().isEmpty) {
          _showStepError('Enter your phone number');
          return false;
        }
        final email = _emailController.text.trim();
        if (email.isEmpty || !email.contains('@')) {
          _showStepError('Enter a valid email');
          return false;
        }
        if (_passwordController.text.length < 6) {
          _showStepError('Password must be at least 6 characters');
          return false;
        }
        return true;
      case 1:
        if (_businessNameController.text.trim().isEmpty) {
          _showStepError('Enter your business name');
          return false;
        }
        if (_businessAddressController.text.trim().isEmpty) {
          _showStepError('Enter your business address');
          return false;
        }
        return true;
      case 2:
        if (_billRulesController.text.trim().isEmpty) {
          _showStepError('Enter bill rules or notes');
          return false;
        }
        if (context.read<RegisterBloc>().state.signatureLocalPath == null) {
          _showStepError('Please add your bill signature image');
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  void _nextStep(RegisterState state) {
    if (!_validateCurrentStep()) return;
    
    // Gating Step 1 with Email OTP
    if (_step == 0 && !state.isEmailVerified) {
      context.read<RegisterBloc>().add(RegisterSendOtpRequested(_emailController.text));
      return;
    }

    if (_step >= _stepLabels.length - 1) return;
    setState(() => _step++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _showOtpBottomSheet(BuildContext context, RegisterState state) {
    final otpController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<RegisterBloc>(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: BlocConsumer<RegisterBloc, RegisterState>(
              listenWhen: (p, c) => p.otpStatus != c.otpStatus,
              listener: (ctx, cState) {
                if (cState.otpStatus == RegisterOtpStatus.verified) {
                  Navigator.of(ctx).pop(); // Close sheet
                  _nextStep(cState); // Advance to Step 2
                } else if (cState.otpStatus == RegisterOtpStatus.error && cState.errorMessage != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(cState.errorMessage!)),
                  );
                }
              },
              builder: (ctx, cState) {
                final isVerifying = cState.otpStatus == RegisterOtpStatus.verifying;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Verify your email',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('We sent a 6-digit code to ${_emailController.text}'),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Enter OTP here',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isVerifying,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isVerifying
                          ? null
                          : () {
                              if (otpController.text.length >= 4) {
                                ctx.read<RegisterBloc>().add(
                                      RegisterVerifyOtpRequested(
                                        _emailController.text.trim(),
                                        otpController.text,
                                      ),
                                    );
                              }
                            },
                      child: isVerifying ? const AppShimmer(child: Text('Verifying...')) : const Text('Verify Email'),
                    ),
                    TextButton(
                      onPressed: isVerifying
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              ctx.read<RegisterBloc>().add(const RegisterOtpStatusCleared());
                            },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _prevStep() {
    if (_step == 0) {
      context.go('/login');
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _submit(File? signatureFile) {
    if (signatureFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a signature image.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    context.read<RegisterBloc>().add(
          RegisterSubmitted(
            RegistrationPayload(
              fullName: _nameController.text.trim(),
              businessName: _businessNameController.text.trim(),
              businessAddress: _businessAddressController.text.trim(),
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              gstNumber: _gstController.text.trim(),
              billRules: _billRulesController.text.trim(),
              signatureLocalPath: signatureFile.path,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (p, c) =>
          p.status != c.status || p.otpStatus != c.otpStatus,
      listener: (context, state) {
        if (state.otpStatus == RegisterOtpStatus.sent) {
          // Show sheet only once when status becomes sent
          _showOtpBottomSheet(context, state);
        }

        if (state.status == RegisterStatus.success) {
          // Initialize app hubs manually since AuthBloc transitioned to authenticated in Step 1
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (uid != null) {
            context.read<DashboardHubBloc>().add(DashboardHubStarted(uid));
            context.read<ConnectivityBloc>().add(const ConnectivityStarted());
            context.read<DayBookBloc>().add(DayBookStarted());
            context.read<LoyaltyBloc>().add(LoadLoyaltyConfig(uid));
            context.read<StockAuditBloc>().add(LoadStockAudits());
          }
          context.go('/app/dashboard');
        } else if ((state.status == RegisterStatus.failure || state.otpStatus == RegisterOtpStatus.error) &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              duration: Duration(
                seconds: state.errorMessage!.length > 120 ? 12 : 8,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final submitting = state.status == RegisterStatus.submitting ||
            state.otpStatus == RegisterOtpStatus.sending;
        final signatureFile = state.signatureLocalPath != null
            ? File(state.signatureLocalPath!)
            : null;
        final isLastStep = _step == _stepLabels.length - 1;

        return AuthScaffold(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: submitting ? null : _prevStep,
          ),
          title: 'Create account',
          subtitle: 'Set up your store in a few quick steps',
          body: AbsorbPointer(
            absorbing: submitting,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: AuthGlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthStepProgressBar(
                        stepCount: _stepLabels.length,
                        currentStep: _step,
                        labels: _stepLabels,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 340,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            RegisterStepPersonalFields(
                              nameController: _nameController,
                              phoneController: _phoneController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: state.obscurePassword,
                              onTogglePassword: () =>
                                  context.read<RegisterBloc>().add(
                                        const RegisterPasswordVisibilityToggled(),
                                      ),
                            ),
                            RegisterStepBusinessFields(
                              businessNameController: _businessNameController,
                              businessAddressController:
                                  _businessAddressController,
                              gstController: _gstController,
                            ),
                            RegisterStepBillingFields(
                              billRulesController: _billRulesController,
                              signatureFile: signatureFile,
                              onPickSignature: _pickSignature,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_step > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _prevStep,
                                child: const Text('Back'),
                              ),
                            ),
                          if (_step > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: _step > 0 ? 1 : 1,
                            child: FilledButton(
                              onPressed: submitting
                                  ? null
                                  : () {
                                      if (isLastStep) {
                                        _submit(signatureFile);
                                      } else {
                                        _nextStep(state);
                                      }
                                    },
                              child: submitting
                                  ? AppShimmer(
                                      child: Text(isLastStep
                                          ? 'Create account'
                                          : 'Continue'),
                                    )
                                  : Text(isLastStep
                                      ? 'Create account'
                                      : 'Continue'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: submitting ? null : () => context.go('/login'),
                        child: const Text('Already have an account? Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
