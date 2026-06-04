import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/reorder_alert.dart';

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

final class InventoryAutomationReorderDismissed extends InventoryAutomationEvent {
  const InventoryAutomationReorderDismissed(this.productId);
  final String productId;

  @override
  List<Object?> get props => [productId];
}
