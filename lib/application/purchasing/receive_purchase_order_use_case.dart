import 'package:inventopos/domain/entities/purchase_order.dart';
import 'package:inventopos/domain/repositories/purchase_order_repository.dart';

class ReceivePurchaseOrderUseCase {
  final PurchaseOrderRepository _repository;

  ReceivePurchaseOrderUseCase(this._repository);

  Future<void> call(String orderId, List<PurchaseOrderLine> receivedLines) {
    return _repository.receivePurchaseOrder(orderId, receivedLines);
  }
}