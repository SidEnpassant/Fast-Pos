import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/domain/registration/registration_payload.dart';
import 'package:inventopos/presentation/register/bloc/register_bloc.dart';
import 'package:inventopos/presentation/register/bloc/register_event.dart';
import 'package:inventopos/presentation/register/bloc/register_state.dart';
import 'package:inventopos/presentation/register/widgets/register_signature_section.dart';
import 'package:inventopos/presentation/register/widgets/register_text_fields.dart';

/// Registration screen — form + [RegisterBloc].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gstController = TextEditingController();
  final _billRulesController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
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
          p.status != c.status &&
          (c.status == RegisterStatus.success ||
              c.status == RegisterStatus.failure),
      listener: (context, state) {
        if (state.status == RegisterStatus.success &&
            state.successEmail != null) {
          context.go('/verify-email', extra: state.successEmail);
        } else if (state.status == RegisterStatus.failure &&
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
        final submitting = state.status == RegisterStatus.submitting;
        final signatureFile = state.signatureLocalPath != null
            ? File(state.signatureLocalPath!)
            : null;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: submitting,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start managing your business with FastPOS',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      RegisterTextFields(
                        nameController: _nameController,
                        businessNameController: _businessNameController,
                        businessAddressController: _businessAddressController,
                        phoneController: _phoneController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        gstController: _gstController,
                        billRulesController: _billRulesController,
                        obscurePassword: state.obscurePassword,
                        onTogglePasswordVisibility: () => context
                            .read<RegisterBloc>()
                            .add(const RegisterPasswordVisibilityToggled()),
                      ),
                      const SizedBox(height: 16),
                      RegisterSignatureSection(
                        signatureFile: signatureFile,
                        onTapPick: _pickSignature,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              submitting ? null : () => _submit(signatureFile),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: submitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Register',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
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
