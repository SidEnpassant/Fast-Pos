import 'package:inventopos/domain/entities/purchase_order.dart';

abstract class PurchaseOrderRepository {
  Stream<List<PurchaseOrder>> watchPurchaseOrdersForUser(String userId);
  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder order);
  Future<PurchaseOrder> updatePurchaseOrder(PurchaseOrder order);
  Future<void> receivePurchaseOrder(String orderId, List<PurchaseOrderLine> receivedLines);
  Future<void> deletePurchaseOrder(String orderId);
}