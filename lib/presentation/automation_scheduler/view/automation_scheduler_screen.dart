import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/automation_scheduler/bloc/automation_scheduler_bloc.dart';
import 'package:inventopos/presentation/automation_scheduler/bloc/automation_scheduler_event.dart';
import 'package:inventopos/presentation/automation_scheduler/bloc/automation_scheduler_state.dart';

class AutomationSchedulerScreen extends StatefulWidget {
  const AutomationSchedulerScreen({super.key});

  @override
  State<AutomationSchedulerScreen> createState() =>
      _AutomationSchedulerScreenState();
}

class _AutomationSchedulerScreenState extends State<AutomationSchedulerScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<AutomationSchedulerBloc>().add(
            AutomationSchedulerStarted(uid),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Scheduled automations',
      body: BlocBuilder<AutomationSchedulerBloc, AutomationSchedulerState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.jobs.isEmpty) {
            return const Center(
              child: Text('Enable Automations in settings to schedule jobs.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.jobs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final job = state.jobs[i];
              return SwitchListTile(
                title: Text(_label(job.triggerType)),
                subtitle: Text(
                  job.lastRunAt != null
                      ? 'Last run: ${job.lastRunAt!.toLocal()}'
                      : 'Cron: ${job.cronExpression ?? "—"}',
                ),
                value: job.enabled,
                onChanged: (v) => context.read<AutomationSchedulerBloc>().add(
                      AutomationSchedulerJobToggled(job.id, v),
                    ),
              );
            },
          );
        },
      ),
    );
  }

  String _label(String type) => switch (type) {
        'daily_briefing' => 'Daily business brief',
        'partial_bill_scan' => 'Partial bill reminders',
        'low_stock_scan' => 'Low stock scan',
        'credit_exposure_scan' => 'Credit exposure scan',
        'dead_stock_scan' => 'Dead stock scan',
        'eod_summary' => 'End-of-day summary',
        'weekly_digest' => 'Weekly digest',
        'expense_spike_scan' => 'Expense spike scan',
        'reorder_digest' => 'Reorder digest',
        _ => type,
      };
}
