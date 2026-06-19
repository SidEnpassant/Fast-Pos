import 'package:inventopos/domain/entities/stock_audit.dart';

abstract class StockAuditRepository {
  Stream<List<StockAudit>> watchAudits(String userId);
  Future<StockAudit?> getAuditById(String id);
  Future<StockAudit> createAudit(StockAudit audit);
  Future<void> updateAuditLine(StockAuditLine line);
  Future<void> completeAudit(String auditId);
  Future<void> cancelAudit(String auditId);
}