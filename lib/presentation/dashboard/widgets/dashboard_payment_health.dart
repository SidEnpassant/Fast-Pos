import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';

/// Month payment mix bar (paid / partial / pending).
class DashboardPaymentHealth extends StatelessWidget {
  const DashboardPaymentHealth({super.key, required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final mix = state.monthPaymentMix;
    if (mix.total == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return AppSectionCard(
      title: 'Payment health (this month)',
      actionLabel: 'Analytics',
      onAction: () => context.go('/app/analysis'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (mix.complete > 0)
                    Expanded(
                      flex: mix.complete,
                      child: const ColoredBox(color: Colors.green),
                    ),
                  if (mix.partial > 0)
                    Expanded(
                      flex: mix.partial,
                      child: const ColoredBox(color: Colors.orange),
                    ),
                  if (mix.pending > 0)
                    Expanded(
                      flex: mix.pending,
                      child: ColoredBox(
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Legend('Paid', mix.complete, Colors.green),
              _Legend('Partial', mix.partial, Colors.orange),
              _Legend('Pending', mix.pending, theme.colorScheme.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label $count', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
