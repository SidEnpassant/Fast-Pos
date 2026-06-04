import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_bloc.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_event.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_event.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_state.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_event.dart';

/// Starts AI-related blocs when dashboard data is available.
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
            context.read<InventoryAutomationBloc>().add(
                  InventoryAutomationStarted(uid),
                );
            context.read<BusinessInsightsAiBloc>().add(
                  BusinessInsightsAiStarted(
                    userId: uid,
                    bills: state.bills ?? [],
                    expenses: state.expenses,
                    products: state.products,
                  ),
                );
          },
        ),
      ],
      child: child,
    );
  }
}
