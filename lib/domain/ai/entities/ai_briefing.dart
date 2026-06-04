import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/ai_insight.dart';

class AiBriefing extends Equatable {
  const AiBriefing({
    required this.markdown,
    this.insights = const [],
  });

  final String markdown;
  final List<AiInsight> insights;

  @override
  List<Object?> get props => [markdown, insights];
}
