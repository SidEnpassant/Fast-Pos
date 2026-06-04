import 'package:equatable/equatable.dart';

class AiPreferences extends Equatable {
  const AiPreferences({
    required this.userId,
    this.enabled = false,
    this.enhancedContext = false,
    this.dailyBriefEnabled = true,
    this.reorderAlertsEnabled = true,
    this.partialBillRemindersEnabled = true,
    this.language = 'en',
    this.dailyTokenBudget = 50000,
  });

  final String userId;
  final bool enabled;
  final bool enhancedContext;
  final bool dailyBriefEnabled;
  final bool reorderAlertsEnabled;
  final bool partialBillRemindersEnabled;
  final String language;
  final int dailyTokenBudget;

  AiPreferences copyWith({
    bool? enabled,
    bool? enhancedContext,
    bool? dailyBriefEnabled,
    bool? reorderAlertsEnabled,
    bool? partialBillRemindersEnabled,
    String? language,
    int? dailyTokenBudget,
  }) =>
      AiPreferences(
        userId: userId,
        enabled: enabled ?? this.enabled,
        enhancedContext: enhancedContext ?? this.enhancedContext,
        dailyBriefEnabled: dailyBriefEnabled ?? this.dailyBriefEnabled,
        reorderAlertsEnabled: reorderAlertsEnabled ?? this.reorderAlertsEnabled,
        partialBillRemindersEnabled:
            partialBillRemindersEnabled ?? this.partialBillRemindersEnabled,
        language: language ?? this.language,
        dailyTokenBudget: dailyTokenBudget ?? this.dailyTokenBudget,
      );

  @override
  List<Object?> get props => [
        userId,
        enabled,
        enhancedContext,
        dailyBriefEnabled,
        reorderAlertsEnabled,
        partialBillRemindersEnabled,
        language,
        dailyTokenBudget,
      ];
}
