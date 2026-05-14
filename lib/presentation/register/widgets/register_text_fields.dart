import 'package:flutter/material.dart';

/// Text fields for [RegisterScreen] (controllers owned by parent).
class RegisterTextFields extends StatelessWidget {
  const RegisterTextFields({
    super.key,
    required this.nameController,
    required this.businessNameController,
    required this.businessAddressController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.gstController,
    required this.billRulesController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
  });

  final TextEditingController nameController;
  final TextEditingController businessNameController;
  final TextEditingController businessAddressController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController gstController;
  final TextEditingController billRulesController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: border,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: businessNameController,
          decoration: InputDecoration(
            labelText: 'Business Name',
            prefixIcon: const Icon(Icons.business_outlined),
            border: border,
          ),
          validator: (v) => (v == null || v.isEmpty)
              ? 'Please enter your business name'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: businessAddressController,
          decoration: InputDecoration(
            labelText: 'Business Address',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: border,
          ),
          validator: (v) => (v == null || v.isEmpty)
              ? 'Please enter your business address'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: border,
          ),
          validator: (v) => (v == null || v.isEmpty)
              ? 'Please enter your phone number'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: border,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your email';
            if (!v.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
            border: border,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter a password';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: gstController,
          decoration: InputDecoration(
            labelText: 'GST Number (Optional)',
            prefixIcon: const Icon(Icons.business),
            border: border,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: billRulesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Bill Rules and Notes (will be auto \nprinted on bill)',
            prefixIcon: const Icon(Icons.rule_folder_outlined),
            border: border,
          ),
          validator: (v) => (v == null || v.isEmpty)
              ? 'Please enter bill rules and notes'
              : null,
        ),
      ],
    );
  }
}
