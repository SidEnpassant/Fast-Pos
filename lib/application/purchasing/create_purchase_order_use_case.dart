import 'package:inventopos/domain/entities/purchase_order.dart';
import 'package:inventopos/domain/repositories/purchase_order_repository.dart';

class CreatePurchaseOrderUseCase {
  final PurchaseOrderRepository _repository;

  CreatePurchaseOrderUseCase(this._repository);

  Future<PurchaseOrder> call(PurchaseOrder order) {
    return _repository.createPurchaseOrder(order);
  }
}