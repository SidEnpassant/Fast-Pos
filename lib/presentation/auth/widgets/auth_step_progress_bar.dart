import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';

class AuthStepProgressBar extends StatelessWidget {
  const AuthStepProgressBar({
    super.key,
    required this.stepCount,
    required this.currentStep,
    required this.labels,
  });

  final int stepCount;
  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(stepCount, (i) {
            final active = i <= currentStep;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < stepCount - 1 ? 6 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${currentStep + 1} of $stepCount · ${labels[currentStep]}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
