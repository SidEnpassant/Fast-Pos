import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/presentation/register/widgets/register_signature_section.dart';

InputDecoration _authFieldDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
  );
}

class RegisterStepPersonalFields extends StatelessWidget {
  const RegisterStepPersonalFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          decoration: _authFieldDecoration(
            label: 'Full name',
            icon: Icons.person_outline,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: _authFieldDecoration(
            label: 'Phone number',
            icon: Icons.phone_outlined,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Enter your phone number'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _authFieldDecoration(
            label: 'Email',
            icon: Icons.email_outlined,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          decoration: _authFieldDecoration(
            label: 'Password',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onTogglePassword,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter a password';
            if (v.length < 6) return 'At least 6 characters';
            return null;
          },
        ),
      ],
    );
  }
}

class RegisterStepBusinessFields extends StatelessWidget {
  const RegisterStepBusinessFields({
    super.key,
    required this.businessNameController,
    required this.businessAddressController,
    required this.gstController,
  });

  final TextEditingController businessNameController;
  final TextEditingController businessAddressController;
  final TextEditingController gstController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: businessNameController,
          textInputAction: TextInputAction.next,
          decoration: _authFieldDecoration(
            label: 'Business name',
            icon: Icons.storefront_outlined,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Enter your business name'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: businessAddressController,
          textInputAction: TextInputAction.next,
          maxLines: 2,
          decoration: _authFieldDecoration(
            label: 'Business address',
            icon: Icons.location_on_outlined,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Enter your business address'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: gstController,
          textInputAction: TextInputAction.done,
          decoration: _authFieldDecoration(
            label: 'GST number (optional)',
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ],
    );
  }
}

class RegisterStepBillingFields extends StatelessWidget {
  const RegisterStepBillingFields({
    super.key,
    required this.billRulesController,
    required this.signatureFile,
    required this.onPickSignature,
  });

  final TextEditingController billRulesController;
  final File? signatureFile;
  final VoidCallback onPickSignature;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: billRulesController,
          maxLines: 3,
          decoration: _authFieldDecoration(
            label: 'Bill rules & notes',
            icon: Icons.rule_folder_outlined,
          ).copyWith(
            helperText: 'Printed automatically on every bill',
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Enter bill rules or notes'
              : null,
        ),
        const SizedBox(height: 16),
        RegisterSignatureSection(
          signatureFile: signatureFile,
          onTapPick: onPickSignature,
        ),
      ],
    );
  }
}
