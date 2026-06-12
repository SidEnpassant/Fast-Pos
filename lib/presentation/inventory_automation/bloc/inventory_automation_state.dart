import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/reorder_alert.dart';
import 'package:inventopos/domain/automation/services/dead_stock_evaluator.dart';
import 'package:inventopos/domain/automation/services/margin_leak_evaluator.dart';

class InventoryAutomationState extends Equatable {
  const InventoryAutomationState({
    this.alerts = const [],
    this.deadStock = const [],
    this.marginLeaks = const [],
    this.dismissedIds = const {},
    this.loading = true,
  });

  final List<ReorderAlert> alerts;
  final List<DeadStockAlert> deadStock;
  final List<MarginLeakAlert> marginLeaks;
  final Set<String> dismissedIds;
  final bool loading;

  List<ReorderAlert> get visibleAlerts =>
      alerts.where((a) => !dismissedIds.contains(a.productId)).toList();

  InventoryAutomationState copyWith({
    List<ReorderAlert>? alerts,
    List<DeadStockAlert>? deadStock,
    List<MarginLeakAlert>? marginLeaks,
    Set<String>? dismissedIds,
    bool? loading,
  }) =>
      InventoryAutomationState(
        alerts: alerts ?? this.alerts,
        deadStock: deadStock ?? this.deadStock,
        marginLeaks: marginLeaks ?? this.marginLeaks,
        dismissedIds: dismissedIds ?? this.dismissedIds,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [alerts, deadStock, marginLeaks, dismissedIds, loading];
}
