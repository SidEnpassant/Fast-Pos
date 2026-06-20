import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';

/// Actionable alerts: dues, stock, sync, offline.
class DashboardNeedsAttention extends StatelessWidget {
  const DashboardNeedsAttention({super.key, required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    if (state.attentionItemCount == 0) return const SizedBox.shrink();

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final items = <Widget>[];

    if (state.partialBillsCount > 0) {
      items.add(
        _AttentionTile(
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.orange,
          title: 'Collect pending payments',
          subtitle:
              '${state.partialBillsCount} bills · ${fmt.format(state.pendingCollectionAmount)} outstanding',
          onTap: () => context.push('/incomplete-transactions'),
        ),
      );
    }
    if (state.outOfStockCount > 0) {
      items.add(
        _AttentionTile(
          icon: Icons.remove_shopping_cart_outlined,
          color: Colors.red,
          title: 'Out of stock items',
          subtitle: '${state.outOfStockCount} SKUs need restocking',
          onTap: () => context.go('/app/inventory'),
        ),
      );
    } else if (state.lowStockCount > 0) {
      items.add(
        _AttentionTile(
          icon: Icons.warning_amber_outlined,
          color: Colors.orange,
          title: 'Low stock alerts',
          subtitle: '${state.lowStockCount} products below minimum',
          onTap: () => context.go('/app/inventory'),
        ),
      );
    }
    if (!state.isOnline) {
      items.add(
        const _AttentionTile(
          icon: Icons.cloud_off_outlined,
          color: Colors.blueGrey,
          title: 'You are offline',
          subtitle: 'Bills and changes sync when back online',
          onTap: null,
        ),
      );
    }
    if (state.pendingSyncCount > 0) {
      items.add(
        _AttentionTile(
          icon: Icons.sync_problem_outlined,
          color: Colors.indigo,
          title: 'Pending sync',
          subtitle: '${state.pendingSyncCount} items waiting to upload',
          onTap: null,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return AppSectionCard(
      title: 'Needs attention',
      child: Column(children: items),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
