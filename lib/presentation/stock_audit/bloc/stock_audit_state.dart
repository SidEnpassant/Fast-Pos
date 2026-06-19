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
    bool clearActiveAudit = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return StockAuditState(
      status: status ?? this.status,
      audits: audits ?? this.audits,
      activeAudit: clearActiveAudit ? null : (activeAudit ?? this.activeAudit),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, audits, activeAudit, errorMessage];
}
