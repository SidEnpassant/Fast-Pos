import 'package:inventopos/domain/entities/bill.dart';

/// Revenue recognition and calendar filters for bills.
abstract final class BillRevenue {
  static double recognizedAmount(Bill bill) {
    switch (bill.paymentStatus.toLowerCase().trim()) {
      case 'complete':
        return bill.totalAmount;
      case 'partial':
        return bill.paidAmount;
      default:
        if (bill.paidAmount > 0) return bill.paidAmount;
        return bill.totalAmount;
    }
  }

  static DateTime localCreatedDate(Bill bill) => bill.createdAt.toLocal();

  static bool isSameCalendarDay(Bill bill, DateTime reference) {
    final local = localCreatedDate(bill);
    final ref = reference.toLocal();
    return local.year == ref.year &&
        local.month == ref.month &&
        local.day == ref.day;
  }

  static bool isSameCalendarMonth(Bill bill, DateTime reference) {
    final local = localCreatedDate(bill);
    final ref = reference.toLocal();
    return local.year == ref.year && local.month == ref.month;
  }
}
