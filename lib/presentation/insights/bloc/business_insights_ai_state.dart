import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/ai_briefing.dart';
import 'package:inventopos/domain/ai/entities/ai_insight.dart';

class BusinessInsightsAiState extends Equatable {
  const BusinessInsightsAiState({
    this.briefing,
    this.insights = const [],
    this.loadingBrief = false,
    this.loadingInsights = true,
    this.error,
  });

  final AiBriefing? briefing;
  final List<AiInsight> insights;
  final bool loadingBrief;
  final bool loadingInsights;
  final String? error;

  int get unreadCount => insights.where((i) => i.isUnread).length;

  BusinessInsightsAiState copyWith({
    AiBriefing? briefing,
    List<AiInsight>? insights,
    bool? loadingBrief,
    bool? loadingInsights,
    String? error,
  }) =>
      BusinessInsightsAiState(
        briefing: briefing ?? this.briefing,
        insights: insights ?? this.insights,
        loadingBrief: loadingBrief ?? this.loadingBrief,
        loadingInsights: loadingInsights ?? this.loadingInsights,
        error: error,
      );

  @override
  List<Object?> get props =>
      [briefing, insights, loadingBrief, loadingInsights, error];
}
