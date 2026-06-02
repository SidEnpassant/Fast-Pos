import 'package:flutter/material.dart';

/// Small badge showing month-over-month % change.
class AnalyticsTrendChip extends StatelessWidget {
  const AnalyticsTrendChip({super.key, required this.changePercent});

  final double? changePercent;

  @override
  Widget build(BuildContext context) {
    if (changePercent == null) {
      return const SizedBox.shrink();
    }
    final pct = changePercent!;
    final up = pct >= 0;
    final color = up ? Colors.green.shade700 : Colors.red.shade700;
    final icon = up ? Icons.arrow_upward : Icons.arrow_downward;
    final label = '${pct.abs().toStringAsFixed(0)}% vs last month';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
