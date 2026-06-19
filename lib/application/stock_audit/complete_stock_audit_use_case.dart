import '../../domain/repositories/stock_audit_repository.dart';

class CompleteStockAuditUseCase {
  final StockAuditRepository _repository;

  CompleteStockAuditUseCase(this._repository);

  Future<void> call(String auditId) async {
    await _repository.completeAudit(auditId);
  }
}