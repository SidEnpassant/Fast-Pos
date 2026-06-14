import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/domain/ai/entities/ai_insight.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_bloc.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_event.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_state.dart';
import 'package:inventopos/presentation/insights/widgets/ai_brief_markdown_view.dart';

class DashboardAiBriefingCard extends StatelessWidget {
  const DashboardAiBriefingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessInsightsAiBloc, BusinessInsightsAiState>(
      builder: (context, state) {
        final hasBrief =
            state.briefing != null && state.briefing!.markdown.trim().isNotEmpty;

        if (!hasBrief) {
          return _EmptyBriefCard(state: state);
        }

        final insights = _displayInsights(state);

        return AppSectionCard(
          title: 'Today\'s AI brief',
          actionLabel: state.loadingBrief ? null : 'Regenerate',
          onAction: state.loadingBrief
              ? null
              : () => context.read<BusinessInsightsAiBloc>().add(
                    const BusinessInsightsAiBriefingRequested(),
                  ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BriefHeader(lastGeneratedAt: state.lastGeneratedAt),
              if (insights.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: insights
                      .take(3)
                      .map((i) => _InsightChip(insight: i))
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
                child: state.loadingBrief
                    ? AppShimmer(
                        child: Column(
                          children: [
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: const BoxDecoration(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: const BoxDecoration(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 16,
                              width: 150,
                              decoration: const BoxDecoration(color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : AiBriefMarkdownView(markdown: state.briefing!.markdown),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  // ── Last updated label ──
                  if (state.lastGeneratedAt != null)
                    Expanded(
                      child: _LastUpdatedLabel(
                        generatedAt: state.lastGeneratedAt!,
                      ),
                    )
                  else
                    const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push('/ai-hub'),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open Automations'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<AiInsight> _displayInsights(BusinessInsightsAiState state) {
    final fromBrief = state.briefing?.insights ?? const [];
    if (fromBrief.isNotEmpty) return fromBrief;
    return state.insights.where((i) => i.isUnread).take(5).toList();
  }
}

// ─── Empty state card ───────────────────────────────────────────────────────

class _EmptyBriefCard extends StatelessWidget {
  const _EmptyBriefCard({required this.state});

  final BusinessInsightsAiState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSectionCard(
      title: 'Today\'s AI brief',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'A short, readable summary of today\'s sales, stock, and collections — powered by Groq AI.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: state.loadingBrief
                ? null
                : () => context.read<BusinessInsightsAiBloc>().add(
                      const BusinessInsightsAiBriefingRequested(),
                    ),
            icon: state.loadingBrief
                ? const Icon(Icons.bolt, color: Colors.transparent)
                : const Icon(Icons.bolt),
            label: state.loadingBrief
                ? const AppShimmer(child: Text('Generating…'))
                : const Text('Generate today\'s brief'),
          ),
          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  _friendlyError(state.error!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('rateLimited') || raw.contains('429')) {
      return 'AI is busy. Please try again in a moment.';
    }
    if (raw.contains('consentDenied') || raw.contains('Automations')) {
      return 'Turn on Automations in My Account → Tools to use this feature.';
    }
    if (raw.length > 120) {
      return 'Could not generate brief. Tap again or check Automations settings.';
    }
    return raw;
  }
}

// ─── Brief header with gradient icon ────────────────────────────────────────

class _BriefHeader extends StatelessWidget {
  const _BriefHeader({required this.lastGeneratedAt});

  final DateTime? lastGeneratedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.85),
                Colors.deepPurple.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: const Icon(Icons.insights, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your shop at a glance',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (lastGeneratedAt != null)
                Text(
                  _formatTimestamp(lastGeneratedAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      return 'Updated ${DateFormat('h:mm a').format(dt)}';
    }
    return 'Updated ${DateFormat('d MMM, h:mm a').format(dt)}';
  }
}

// ─── Last-updated label at bottom ───────────────────────────────────────────

class _LastUpdatedLabel extends StatelessWidget {
  const _LastUpdatedLabel({required this.generatedAt});

  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final diff = now.difference(generatedAt);

    String label;
    if (diff.inMinutes < 1) {
      label = 'Generated just now';
    } else if (diff.inMinutes < 60) {
      label = 'Generated ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      label = 'Generated at ${DateFormat('h:mm a').format(generatedAt)}';
    } else {
      label =
          'Generated ${DateFormat('d MMM, h:mm a').format(generatedAt)}';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Insight chip ───────────────────────────────────────────────────────────

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.insight});

  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (insight.type) {
      'collections' => (Icons.payments_outlined, Colors.orange),
      'inventory' => (Icons.inventory_2_outlined, Colors.teal),
      'revenue' => (Icons.trending_up, Colors.green),
      'profit' => (Icons.account_balance_wallet_outlined, Colors.indigo),
      _ => (Icons.lightbulb_outline, theme.colorScheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              insight.title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
