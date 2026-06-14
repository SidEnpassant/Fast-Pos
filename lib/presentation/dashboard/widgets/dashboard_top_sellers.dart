import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';

class DashboardTopSellers extends StatelessWidget {
  const DashboardTopSellers({super.key, required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final top = state.topProductsThisMonth.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return AppSectionCard(
      title: 'Top sellers (this month)',
      actionLabel: 'Analytics',
      onAction: () => context.go('/app/analysis'),
      child: Column(
        children: top.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Text(
                  '${p.unitsSold} sold',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(width: 12),
                Text(
                  fmt.format(p.revenue),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
