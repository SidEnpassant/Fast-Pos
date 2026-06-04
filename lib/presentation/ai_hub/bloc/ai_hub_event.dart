import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';

sealed class AiHubEvent extends Equatable {
  const AiHubEvent();

  @override
  List<Object?> get props => [];
}

final class AiHubStarted extends AiHubEvent {
  const AiHubStarted(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class AiHubPreferencesReceived extends AiHubEvent {
  const AiHubPreferencesReceived(this.preferences);
  final AiPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}

final class AiHubUnreadCountReceived extends AiHubEvent {
  const AiHubUnreadCountReceived(this.count);
  final int count;

  @override
  List<Object?> get props => [count];
}
