import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/reorder_alert.dart';
import 'package:inventopos/domain/automation/services/dead_stock_evaluator.dart';
import 'package:inventopos/domain/automation/services/margin_leak_evaluator.dart';

sealed class InventoryAutomationEvent extends Equatable {
  const InventoryAutomationEvent();

  @override
  List<Object?> get props => [];
}

final class InventoryAutomationStarted extends InventoryAutomationEvent {
  const InventoryAutomationStarted(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class InventoryAutomationAlertsReceived extends InventoryAutomationEvent {
  const InventoryAutomationAlertsReceived(this.alerts);
  final List<ReorderAlert> alerts;

  @override
  List<Object?> get props => [alerts];
}

final class InventoryAutomationReorderDismissed
    extends InventoryAutomationEvent {
  const InventoryAutomationReorderDismissed(this.productId);
  final String productId;

  @override
  List<Object?> get props => [productId];
}

final class InventoryAutomationExtendedLoaded extends InventoryAutomationEvent {
  const InventoryAutomationExtendedLoaded({
    required this.deadStock,
    required this.marginLeaks,
  });
  final List<DeadStockAlert> deadStock;
  final List<MarginLeakAlert> marginLeaks;

  @override
  List<Object?> get props => [deadStock, marginLeaks];
}
