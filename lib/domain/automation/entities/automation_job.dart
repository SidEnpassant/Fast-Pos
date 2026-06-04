import 'package:equatable/equatable.dart';

class AutomationJob extends Equatable {
  const AutomationJob({
    required this.id,
    required this.userId,
    required this.triggerType,
    this.cronExpression,
    this.enabled = true,
    this.lastRunAt,
    this.configJson = const {},
  });

  final String id;
  final String userId;
  final String triggerType;
  final String? cronExpression;
  final bool enabled;
  final DateTime? lastRunAt;
  final Map<String, dynamic> configJson;

  @override
  List<Object?> get props =>
      [id, userId, triggerType, cronExpression, enabled, lastRunAt, configJson];
}
