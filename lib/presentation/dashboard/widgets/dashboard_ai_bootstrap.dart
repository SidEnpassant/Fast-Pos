import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/collections_automation/bloc/collections_automation_bloc.dart';
import 'package:inventopos/presentation/collections_automation/bloc/collections_automation_event.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';
import 'package:inventopos/presentation/day_operations/bloc/day_operations_bloc.dart';
import 'package:inventopos/presentation/day_operations/bloc/day_operations_event.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_bloc.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_event.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_event.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_state.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_event.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_state.dart';

/// Starts automation-related blocs when dashboard data is available.
class DashboardAiBootstrap extends StatelessWidget {
  const DashboardAiBootstrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BusinessInsightsAiBloc, BusinessInsightsAiState>(
          listenWhen: (p, c) => p.unreadCount != c.unreadCount,
          listener: (context, state) {
            context.read<DashboardHubBloc>().add(
                  DashboardHubAiUnreadChanged(state.unreadCount),
                );
          },
        ),
        BlocListener<DashboardHubBloc, DashboardHubState>(
          listenWhen: (prev, curr) =>
              !curr.loading && curr.bills != null && prev.bills == null,
          listener: (context, state) {
            final uid = context.read<AuthRepository>().currentSession?.userId;
            if (uid == null) return;
            final bills = state.bills ?? [];
            final customers = state.customers;
            final expenses = state.expenses;
            context.read<InventoryAutomationBloc>().add(
                  InventoryAutomationStarted(uid),
                );
            context.read<BusinessInsightsAiBloc>().add(
                  BusinessInsightsAiStarted(
                    userId: uid,
                    bills: bills,
                    expenses: expenses,
                    products: state.products,
                  ),
                );
            context.read<CollectionsAutomationBloc>().add(
                  CollectionsAutomationStarted(
                    userId: uid,
                    bills: bills,
                    customers: customers,
                  ),
                );
          },
        ),
        BlocListener<InventoryAutomationBloc, InventoryAutomationState>(
          listenWhen: (p, c) => !c.loading && p.loading && !c.loading,
          listener: (context, invState) {
            final hub = context.read<DashboardHubBloc>().state;
            final bills = hub.bills ?? [];
            context.read<DayOperationsBloc>().add(
                  DayOperationsStarted(
                    bills: bills,
                    reorderAlertCount: invState.alerts.length,
                    expenses: hub.expenses,
                  ),
                );
          },
        ),
      ],
      child: child,
    );
  }
}
