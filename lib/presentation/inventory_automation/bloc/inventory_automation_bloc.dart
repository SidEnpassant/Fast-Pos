import 'package:bloc/bloc.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/automation/automation_use_cases.dart';
import 'package:inventopos/application/inventory/evaluate_reorder_alerts_use_case.dart';
import 'package:inventopos/domain/automation/policies/automation_policy.dart';
import 'package:inventopos/domain/automation/services/dead_stock_evaluator.dart';
import 'package:inventopos/domain/automation/services/margin_leak_evaluator.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_event.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_state.dart';

class InventoryAutomationBloc
    extends Bloc<InventoryAutomationEvent, InventoryAutomationState> {
  InventoryAutomationBloc(
    this._evaluate,
    this._observePrefs,
    this._deadStock,
    this._marginLeaks,
  ) : super(const InventoryAutomationState()) {
    on<InventoryAutomationStarted>(_onStarted);
    on<InventoryAutomationAlertsReceived>(_onReceived);
    on<InventoryAutomationReorderDismissed>(_onDismissed);
    on<InventoryAutomationExtendedLoaded>(_onExtended);
  }

  final EvaluateReorderAlertsUseCase _evaluate;
  final ObserveAiPreferencesUseCase _observePrefs;
  final EvaluateDeadStockUseCase _deadStock;
  final EvaluateMarginLeaksUseCase _marginLeaks;

  Future<void> _onStarted(
    InventoryAutomationStarted event,
    Emitter<InventoryAutomationState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final prefs = await _observePrefs(event.userId).first;
    if (!AutomationPolicy.canRunReorderAlerts(prefs)) {
      emit(state.copyWith(loading: false, alerts: const []));
      return;
    }
    final alerts = await _evaluate(event.userId);
    final visible = alerts
        .where((a) => !state.dismissedIds.contains(a.productId))
        .toList();
    List<DeadStockAlert> dead = const [];
    List<MarginLeakAlert> margins = const [];
    if (AutomationPolicy.canRunDeadStockAlerts(prefs)) {
      dead = await _deadStock(event.userId);
    }
    if (AutomationPolicy.canRunMarginAlerts(prefs)) {
      margins = await _marginLeaks(event.userId);
    }
    add(InventoryAutomationAlertsReceived(visible));
    add(InventoryAutomationExtendedLoaded(deadStock: dead, marginLeaks: margins));
  }

  void _onReceived(
    InventoryAutomationAlertsReceived event,
    Emitter<InventoryAutomationState> emit,
  ) {
    emit(state.copyWith(alerts: event.alerts, loading: false));
  }

  void _onExtended(
    InventoryAutomationExtendedLoaded event,
    Emitter<InventoryAutomationState> emit,
  ) {
    emit(state.copyWith(
      deadStock: event.deadStock,
      marginLeaks: event.marginLeaks,
    ));
  }

  void _onDismissed(
    InventoryAutomationReorderDismissed event,
    Emitter<InventoryAutomationState> emit,
  ) {
    emit(state.copyWith(
      dismissedIds: {...state.dismissedIds, event.productId},
      alerts: state.alerts
          .where((a) => a.productId != event.productId)
          .toList(),
    ));
  }
}
