import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/ai_briefing.dart';
import 'package:inventopos/domain/ai/entities/ai_insight.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';

sealed class BusinessInsightsAiEvent extends Equatable {
  const BusinessInsightsAiEvent();

  @override
  List<Object?> get props => [];
}

final class BusinessInsightsAiStarted extends BusinessInsightsAiEvent {
  const BusinessInsightsAiStarted({
    required this.userId,
    this.bills = const [],
    this.expenses = const [],
    this.products = const [],
  });
  final String userId;
  final List<Bill> bills;
  final List<Expense> expenses;
  final List<Product> products;

  @override
  List<Object?> get props => [userId, bills, expenses, products];
}

final class BusinessInsightsAiBriefingRequested
    extends BusinessInsightsAiEvent {
  const BusinessInsightsAiBriefingRequested();
}

final class BusinessInsightsAiBriefingReceived extends BusinessInsightsAiEvent {
  const BusinessInsightsAiBriefingReceived(this.briefing, this.error);
  final AiBriefing? briefing;
  final String? error;

  @override
  List<Object?> get props => [briefing, error];
}

final class BusinessInsightsAiInsightsReceived extends BusinessInsightsAiEvent {
  const BusinessInsightsAiInsightsReceived(this.insights);
  final List<AiInsight> insights;

  @override
  List<Object?> get props => [insights];
}

final class BusinessInsightsAiInsightMarkedRead
    extends BusinessInsightsAiEvent {
  const BusinessInsightsAiInsightMarkedRead(this.insightId);
  final String insightId;

  @override
  List<Object?> get props => [insightId];
}
