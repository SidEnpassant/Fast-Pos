import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/reorder_alert.dart';

class InventoryAutomationState extends Equatable {
  const InventoryAutomationState({
    this.alerts = const [],
    this.dismissedIds = const {},
    this.loading = true,
  });

  final List<ReorderAlert> alerts;
  final Set<String> dismissedIds;
  final bool loading;

  List<ReorderAlert> get visibleAlerts =>
      alerts.where((a) => !dismissedIds.contains(a.productId)).toList();

  InventoryAutomationState copyWith({
    List<ReorderAlert>? alerts,
    Set<String>? dismissedIds,
    bool? loading,
  }) =>
      InventoryAutomationState(
        alerts: alerts ?? this.alerts,
        dismissedIds: dismissedIds ?? this.dismissedIds,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [alerts, dismissedIds, loading];
}
