import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTapPick,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          height: 140,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: signatureFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.draw_outlined,
                      size: 32,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add signature image',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Shown on printed bills',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Image.file(signatureFile!, fit: BoxFit.contain),
                ),
        ),
      ),
    );
  }
}
