import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_quick_action_tile.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSectionCard(
      title: 'Quick actions',
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: [
          AppQuickActionTile(
            label: 'New Bill',
            icon: Icons.receipt_long,
            color: theme.colorScheme.primary,
            onTap: () => context.go('/app/new-bill'),
          ),
          AppQuickActionTile(
            label: 'Inventory',
            icon: Icons.inventory_2,
            color: Colors.teal,
            onTap: () => context.go('/app/inventory'),
          ),
          AppQuickActionTile(
            label: 'Analytics',
            icon: Icons.analytics,
            color: Colors.indigo,
            onTap: () => context.go('/app/analysis'),
          ),
          AppQuickActionTile(
            label: 'Customers',
            icon: Icons.people,
            color: Colors.deepOrange,
            onTap: () => context.push('/customers'),
          ),
          AppQuickActionTile(
            label: 'Expenses',
            icon: Icons.payments,
            color: Colors.brown,
            onTap: () => context.push('/expenses'),
          ),
          AppQuickActionTile(
            label: 'Import',
            icon: Icons.upload_file,
            color: Colors.blueGrey,
            onTap: () => context.push('/import-export'),
          ),
          AppQuickActionTile(
            label: 'Sales',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onTap: () => context.push('/complete-transactions'),
          ),
          AppQuickActionTile(
            label: 'Dues',
            icon: Icons.pending_actions,
            color: Colors.orange,
            onTap: () => context.push('/incomplete-transactions'),
          ),
        ],
      ),
    );
  }
}
