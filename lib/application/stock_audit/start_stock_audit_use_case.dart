import 'package:uuid/uuid.dart';
import '../../domain/entities/stock_audit.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/stock_audit_repository.dart';

class StartStockAuditUseCase {
  final ProductRepository _productRepository;
  final StockAuditRepository _auditRepository;

  StartStockAuditUseCase(this._productRepository, this._auditRepository);

  Future<StockAudit> call(String userId, {String? notes}) async {
    final products = await _productRepository.fetchProductsForUser(userId);
    final uuid = const Uuid();
    final auditId = uuid.v4();

    final lines = products.map((p) {
      return StockAuditLine(
        id: uuid.v4(),
        auditId: auditId,
        productId: p.id,
        productName: p.name,
        systemQty: p.stockQuantity,
        physicalQty: p.stockQuantity, // Pre-fill with system quantity
        variance: 0,
      );
    }).toList();

    final audit = StockAudit(
      id: auditId,
      userId: userId,
      auditDate: DateTime.now(),
      status: StockAuditStatus.inProgress,
      notes: notes,
      createdAt: DateTime.now(),
      lines: lines,
    );

    return await _auditRepository.createAudit(audit);
  }
}