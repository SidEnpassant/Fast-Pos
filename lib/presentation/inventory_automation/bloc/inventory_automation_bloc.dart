import 'package:bloc/bloc.dart';
import 'package:inventopos/application/inventory/evaluate_reorder_alerts_use_case.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_event.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_state.dart';

class InventoryAutomationBloc
    extends Bloc<InventoryAutomationEvent, InventoryAutomationState> {
  InventoryAutomationBloc(this._evaluate)
      : super(const InventoryAutomationState()) {
    on<InventoryAutomationStarted>(_onStarted);
    on<InventoryAutomationAlertsReceived>(_onReceived);
    on<InventoryAutomationReorderDismissed>(_onDismissed);
  }

  final EvaluateReorderAlertsUseCase _evaluate;

  Future<void> _onStarted(
    InventoryAutomationStarted event,
    Emitter<InventoryAutomationState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final alerts = await _evaluate(event.userId);
    add(InventoryAutomationAlertsReceived(alerts));
  }

  void _onReceived(
    InventoryAutomationAlertsReceived event,
    Emitter<InventoryAutomationState> emit,
  ) {
    emit(state.copyWith(alerts: event.alerts, loading: false));
  }

  void _onDismissed(
    InventoryAutomationReorderDismissed event,
    Emitter<InventoryAutomationState> emit,
  ) {
    emit(state.copyWith(
      dismissedIds: {...state.dismissedIds, event.productId},
    ));
  }
}
