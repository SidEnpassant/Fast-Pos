import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/ai_hub/bloc/ai_hub_bloc.dart';
import 'package:inventopos/presentation/ai_hub/bloc/ai_hub_event.dart';
import 'package:inventopos/presentation/ai_hub/bloc/ai_hub_state.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_bloc.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_event.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_state.dart';
import 'package:inventopos/presentation/insights/widgets/ai_brief_markdown_view.dart';

class AiHubScreen extends StatefulWidget {
  const AiHubScreen({super.key});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<AiHubBloc>().add(AiHubStarted(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Automations',
      body: BlocBuilder<AiHubBloc, AiHubState>(
        builder: (context, hub) {
          if (hub.loading) {
            return const AppSkeletonList(itemCount: 8);
          }
          if (!hub.aiEnabled) {
            return _EnablePrompt(
                onSettings: () => context.push('/ai-settings'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Automation settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/ai-settings'),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Scheduled jobs'),
                subtitle: const Text('Cron automations and last run times'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/automation-jobs'),
              ),
              BlocBuilder<BusinessInsightsAiBloc, BusinessInsightsAiState>(
                builder: (context, ins) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (ins.briefing?.markdown.isNotEmpty == true)
                            AiBriefMarkdownView(
                              markdown: ins.briefing!.markdown,
                              maxBullets: 8,
                            )
                          else
                            const Text(
                              'Generate your daily business brief for a '
                              'readable summary of sales and stock.',
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton(
                            onPressed: ins.loadingBrief
                                ? null
                                : () => context.read<BusinessInsightsAiBloc>().add(
                                    const BusinessInsightsAiBriefingRequested()),
                            child: const Text('Refresh brief'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (hub.unreadInsights > 0)
                ListTile(
                  leading: Badge(
                    label: Text('${hub.unreadInsights}'),
                    child: const Icon(Icons.lightbulb),
                  ),
                  title: const Text('Unread insights'),
                  subtitle: const Text('Synced from cloud automation'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EnablePrompt extends StatelessWidget {
  const _EnablePrompt({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.smart_toy_outlined, size: 64),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Enable Automations for daily briefs, collections reminders, reorder alerts, and WhatsApp follow-ups.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onSettings,
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}
