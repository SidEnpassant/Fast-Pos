import 'package:inventopos/domain/ai/entities/ai_insight.dart';

abstract class AiInsightsPort {
  Stream<List<AiInsight>> watchForUser(String userId);

  Future<void> markRead(String insightId);

  Future<int> unreadCount(String userId);
}
