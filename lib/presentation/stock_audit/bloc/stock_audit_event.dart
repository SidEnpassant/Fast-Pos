part of 'stock_audit_bloc.dart';

abstract class StockAuditEvent extends Equatable {
  const StockAuditEvent();

  @override
  List<Object?> get props => [];
}

class LoadStockAudits extends StockAuditEvent {}

class StockAuditsUpdated extends StockAuditEvent {
  final List<StockAudit> audits;

  const StockAuditsUpdated(this.audits);

  @override
  List<Object?> get props => [audits];
}

class StartNewAudit extends StockAuditEvent {
  final String? notes;

  const StartNewAudit({this.notes});

  @override
  List<Object?> get props => [notes];
}

class UpdateAuditLineQuantity extends StockAuditEvent {
  final String auditId;
  final String productId;
  final double physicalQty;

  const UpdateAuditLineQuantity({
    required this.auditId,
    required this.productId,
    required this.physicalQty,
  });

  @override
  List<Object?> get props => [auditId, productId, physicalQty];
}

class CompleteAudit extends StockAuditEvent {
  final String auditId;

  const CompleteAudit(this.auditId);

  @override
  List<Object?> get props => [auditId];
}

class CancelAudit extends StockAuditEvent {
  final String auditId;

  const CancelAudit(this.auditId);

  @override
  List<Object?> get props => [auditId];
}
