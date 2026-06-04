import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';

class AiHubState extends Equatable {
  const AiHubState({
    this.preferences,
    this.unreadInsights = 0,
    this.loading = true,
  });

  final AiPreferences? preferences;
  final int unreadInsights;
  final bool loading;

  bool get aiEnabled => preferences?.enabled ?? false;

  AiHubState copyWith({
    AiPreferences? preferences,
    int? unreadInsights,
    bool? loading,
  }) =>
      AiHubState(
        preferences: preferences ?? this.preferences,
        unreadInsights: unreadInsights ?? this.unreadInsights,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [preferences, unreadInsights, loading];
}
