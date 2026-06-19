import 'package:equatable/equatable.dart';

sealed class AutomationSchedulerEvent extends Equatable {
  const AutomationSchedulerEvent();
  @override
  List<Object?> get props => [];
}

final class AutomationSchedulerStarted extends AutomationSchedulerEvent {
  const AutomationSchedulerStarted(this.userId);
  final String userId;
  @override
  List<Object?> get props => [userId];
}

final class AutomationSchedulerJobToggled extends AutomationSchedulerEvent {
  const AutomationSchedulerJobToggled(this.jobId, this.enabled);
  final String jobId;
  final bool enabled;
  @override
  List<Object?> get props => [jobId, enabled];
}

final class AutomationSchedulerRefreshRequested
    extends AutomationSchedulerEvent {
  const AutomationSchedulerRefreshRequested();
}

final class AutomationSchedulerJobsReceived extends AutomationSchedulerEvent {
  const AutomationSchedulerJobsReceived(this.jobs);
  final List<dynamic> jobs;
  @override
  List<Object?> get props => [jobs];
}
