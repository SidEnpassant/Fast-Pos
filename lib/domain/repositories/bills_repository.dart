import 'package:inventopos/domain/entities/bill.dart';

/// Bills table streams for the signed-in user.
abstract class BillsRepository {
  /// Empty stream if there is no signed-in user.
  Stream<List<Bill>> watchBillsForCurrentUser();

  /// Inserts a bill row for the current user. Returns new bill `id`.
  Future<String> createBill({
    required String businessName,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> productsJson,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethod,
    required String paymentStatus,
  });

  /// Server-side sequential display number (RPC).
  Future<String> nextBillSequenceNumber();
}
