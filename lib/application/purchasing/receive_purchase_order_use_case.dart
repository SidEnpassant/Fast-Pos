import 'package:inventopos/domain/entities/purchase_order.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/domain/repositories/purchase_order_repository.dart';

class ReceivePurchaseOrderUseCase {
  final PurchaseOrderRepository _poRepo;
  final ProductRepository _productRepo;

  ReceivePurchaseOrderUseCase(this._poRepo, this._productRepo);

  Future<void> call(String orderId, List<PurchaseOrderLine> receivedLines) async {
    // 1. Mark PO as received
    await _poRepo.receivePurchaseOrder(orderId, receivedLines);

    // 2. Increment stock for all received lines
    for (final line in receivedLines) {
      if (line.receivedQty <= 0) continue;
      
      final product = await _productRepo.findById(line.productId);
      if (product != null) {
        final updatedProduct = product.copyWith(
          stockQuantity: product.stockQuantity + line.receivedQty,
        );
        await _productRepo.updateProduct(updatedProduct);
      }
    }
  }
}