import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_quick_action_tile.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duesBadge = state.partialBillsCount > 0
        ? '${state.partialBillsCount}'
        : null;
    final stockBadge = state.lowStockCount > 0 ? '${state.lowStockCount}' : null;

    return AppSectionCard(
      title: 'Quick actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionGroup(
            label: 'Sell',
            children: [
              AppQuickActionTile(
                label: 'New bill',
                icon: Icons.point_of_sale,
                color: theme.colorScheme.primary,
                onTap: () => context.go('/app/new-bill'),
              ),
              AppQuickActionTile(
                label: 'Sales',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                onTap: () => context.push('/complete-transactions'),
              ),
              AppQuickActionTile(
                label: 'Pending',
                icon: Icons.pending_actions,
                color: Colors.orange,
                badge: duesBadge,
                onTap: () => context.push('/incomplete-transactions'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionGroup(
            label: 'Manage',
            children: [
              AppQuickActionTile(
                label: 'Inventory',
                icon: Icons.inventory_2_outlined,
                color: Colors.teal,
                badge: stockBadge,
                onTap: () => context.go('/app/inventory'),
              ),
              AppQuickActionTile(
                label: 'Customers',
                icon: Icons.people_outline,
                color: Colors.deepOrange,
                onTap: () => context.push('/customers'),
              ),
              AppQuickActionTile(
                label: 'Expenses',
                icon: Icons.receipt_long_outlined,
                color: Colors.brown,
                onTap: () => context.push('/expenses'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionGroup(
            label: 'Grow',
            children: [
              AppQuickActionTile(
                label: 'Smart AI',
                icon: Icons.smart_toy_outlined,
                color: Colors.deepPurple,
                onTap: () => context.push('/ai-hub'),
              ),
              AppQuickActionTile(
                label: 'Analytics',
                icon: Icons.analytics_outlined,
                color: Colors.indigo,
                onTap: () => context.go('/app/analysis'),
              ),
              AppQuickActionTile(
                label: 'Import CSV',
                icon: Icons.upload_file_outlined,
                color: Colors.blueGrey,
                onTap: () => context.push('/import-export'),
              ),
              AppQuickActionTile(
                label: 'Printer',
                icon: Icons.print_outlined,
                color: Colors.blue,
                onTap: () => context.push('/printer-setup'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: children,
        ),
      ],
    );
  }
}
