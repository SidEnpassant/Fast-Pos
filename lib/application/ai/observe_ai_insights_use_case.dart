import 'package:inventopos/domain/ai/entities/ai_insight.dart';
import 'package:inventopos/domain/ai/repositories/ai_insights_port.dart';

class ObserveAiInsightsUseCase {
  ObserveAiInsightsUseCase(this._insights);

  final AiInsightsPort _insights;

  Stream<List<AiInsight>> call(String userId) => _insights.watchForUser(userId);
}
