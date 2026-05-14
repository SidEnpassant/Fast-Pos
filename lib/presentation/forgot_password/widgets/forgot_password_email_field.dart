import 'package:flutter/material.dart';

class ForgotPasswordEmailField extends StatelessWidget {
  const ForgotPasswordEmailField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.emailAddress,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please Enter Email';
          }
          return null;
        },
        decoration: const InputDecoration(
          hintText: 'Email',
          hintStyle: TextStyle(fontSize: 18, color: Colors.white),
          prefixIcon: Icon(
            Icons.person,
            color: Colors.white70,
            size: 30,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
