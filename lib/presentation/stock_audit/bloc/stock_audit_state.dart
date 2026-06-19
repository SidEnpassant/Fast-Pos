part of 'stock_audit_bloc.dart';

enum StockAuditViewState { initial, loading, success, failure }

class StockAuditState extends Equatable {
  final StockAuditViewState status;
  final List<StockAudit> audits;
  final StockAudit? activeAudit;
  final String? errorMessage;

  const StockAuditState({
    this.status = StockAuditViewState.initial,
    this.audits = const [],
    this.activeAudit,
    this.errorMessage,
  });

  StockAuditState copyWith({
    StockAuditViewState? status,
    List<StockAudit>? audits,
    StockAudit? activeAudit,
    String? errorMessage,
  }) {
    return StockAuditState(
      status: status ?? this.status,
      audits: audits ?? this.audits,
      activeAudit: activeAudit ?? this.activeAudit,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, audits, activeAudit, errorMessage];
}
