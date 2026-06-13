import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_event.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_state.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/presentation/forgot_password/widgets/forgot_password_email_field.dart';
import 'package:inventopos/presentation/forgot_password/widgets/forgot_password_footer_links.dart';
import 'package:inventopos/presentation/forgot_password/widgets/forgot_password_header.dart';

/// Password recovery (Supabase reset email). View only — logic in [ForgotPasswordBloc].
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (p, c) =>
          p.status != c.status &&
          (c.status == ForgotPasswordStatus.success ||
              c.status == ForgotPasswordStatus.failure),
      listener: (context, state) {
        if (state.status == ForgotPasswordStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password Reset Email has been sent !',
                style: TextStyle(fontSize: 20),
              ),
            ),
          );
          context
              .read<ForgotPasswordBloc>()
              .add(const ForgotPasswordUiCleared());
        } else if (state.status == ForgotPasswordStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage!,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == ForgotPasswordStatus.loading;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              const ForgotPasswordHeader(),
              Expanded(
                child: AbsorbPointer(
                  absorbing: loading,
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ListView(
                        children: [
                          ForgotPasswordEmailField(
                              controller: _emailController),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: () {
                              if (loading) return;
                              if (_formKey.currentState!.validate()) {
                                context.read<ForgotPasswordBloc>().add(
                                      ForgotPasswordSubmitted(
                                        _emailController.text,
                                      ),
                                    );
                              }
                            },
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: loading
                                    ? const AppShimmer(
                                        child: Text(
                                          'Send Email',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Send Email',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          const ForgotPasswordFooterLinks(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
