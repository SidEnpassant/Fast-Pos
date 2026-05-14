import 'dart:io';

import 'package:flutter/material.dart';

class RegisterSignatureSection extends StatelessWidget {
  const RegisterSignatureSection({
    super.key,
    required this.signatureFile,
    required this.onTapPick,
  });

  final File? signatureFile;
  final VoidCallback onTapPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapPick,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: signatureFile == null
            ? const Center(
                child: Text(
                  'Tap to add signature\n(which will be auto printed on bill)',
                  textAlign: TextAlign.center,
                ),
              )
            : Image.file(
                signatureFile!,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
