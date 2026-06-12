import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/automation/entities/automation_job.dart';

class AutomationSchedulerState extends Equatable {
  const AutomationSchedulerState({
    this.jobs = const [],
    this.loading = false,
    this.error,
  });

  final List<AutomationJob> jobs;
  final bool loading;
  final String? error;

  AutomationSchedulerState copyWith({
    List<AutomationJob>? jobs,
    bool? loading,
    String? error,
  }) =>
      AutomationSchedulerState(
        jobs: jobs ?? this.jobs,
        loading: loading ?? this.loading,
        error: error,
      );

  @override
  List<Object?> get props => [jobs, loading, error];
}
