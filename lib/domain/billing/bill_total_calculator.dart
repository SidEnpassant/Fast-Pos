import 'package:inventopos/domain/entities/bill.dart';

/// Pure totals for bills and line items (domain logic).
abstract final class BillTotalCalculator {
  static double sumLineItems(List<BillLineItem> items) {
    return items.fold<double>(0, (sum, e) => sum + e.totalPrice);
  }
}
