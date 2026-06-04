import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/router/app_shell_navigation.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_bloc.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_event.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_state.dart';

class DashboardReorderAlerts extends StatelessWidget {
  const DashboardReorderAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryAutomationBloc, InventoryAutomationState>(
      builder: (context, state) {
        final alerts = state.visibleAlerts;
        if (state.loading || alerts.isEmpty) return const SizedBox.shrink();
        return AppSectionCard(
          title: 'Reorder soon',
          actionLabel: 'Inventory',
          onAction: () => goAppShellBranch(context, AppShellBranch.inventory),
          child: Column(
            children: alerts.take(3).map((a) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.inventory_2, color: Colors.orange),
                title: Text(a.productName),
                subtitle: Text(
                  'Stock ${a.stockQuantity} · ~${a.daysRemaining.toStringAsFixed(1)} days left',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => context.read<InventoryAutomationBloc>().add(
                        InventoryAutomationReorderDismissed(a.productId),
                      ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
