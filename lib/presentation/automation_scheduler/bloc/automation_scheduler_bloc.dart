import 'package:bloc/bloc.dart';
import 'package:inventopos/application/automation/automation_use_cases.dart';
import 'package:inventopos/domain/automation/entities/automation_job.dart';
import 'package:inventopos/presentation/automation_scheduler/bloc/automation_scheduler_event.dart';
import 'package:inventopos/presentation/automation_scheduler/bloc/automation_scheduler_state.dart';

class AutomationSchedulerBloc
    extends Bloc<AutomationSchedulerEvent, AutomationSchedulerState> {
  AutomationSchedulerBloc(this._list, this._toggle)
      : super(const AutomationSchedulerState()) {
    on<AutomationSchedulerStarted>(_onStarted);
    on<AutomationSchedulerRefreshRequested>(_onRefresh);
    on<AutomationSchedulerJobToggled>(_onToggle);
    on<AutomationSchedulerJobsReceived>(_onReceived);
  }

  final ListAutomationJobsUseCase _list;
  final ToggleAutomationJobUseCase _toggle;
  String? _userId;

  Future<void> _onStarted(
    AutomationSchedulerStarted event,
    Emitter<AutomationSchedulerState> emit,
  ) async {
    _userId = event.userId;
    emit(state.copyWith(loading: true));
    final jobs = await _list(event.userId);
    add(AutomationSchedulerJobsReceived(jobs));
  }

  Future<void> _onRefresh(
    AutomationSchedulerRefreshRequested event,
    Emitter<AutomationSchedulerState> emit,
  ) async {
    final uid = _userId;
    if (uid == null) return;
    add(AutomationSchedulerStarted(uid));
  }

  Future<void> _onToggle(
    AutomationSchedulerJobToggled event,
    Emitter<AutomationSchedulerState> emit,
  ) async {
    await _toggle(event.jobId, event.enabled);
    add(const AutomationSchedulerRefreshRequested());
  }

  void _onReceived(
    AutomationSchedulerJobsReceived event,
    Emitter<AutomationSchedulerState> emit,
  ) {
    emit(state.copyWith(
      jobs: event.jobs.cast<AutomationJob>(),
      loading: false,
    ));
  }
}
