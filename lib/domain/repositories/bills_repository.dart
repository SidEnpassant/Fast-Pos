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
    String? clientId,
    String? customerId,
    List<Map<String, dynamic>>? discountBreakdown,
    String? contentHash,
  });

  /// Server-side sequential display number (RPC).
  Future<String> nextBillSequenceNumber();

  /// Partial-payment bills for [userId] (`payment_status` = `partial`).
  Future<List<Bill>> fetchPartialBillsForUser(String userId);

  /// Replace signed bill image in storage and update `bills` row URLs.
  Future<void> replaceSignedBillFromLocalFile({
    required String billId,
    required String localFilePath,
  });

  /// Deletes bill row; best-effort removes `signed_bills/{billId}.jpg`.
  Future<void> deleteBillById(String billId);

  /// Updates paid amount and derived payment status / `last_updated`.
  Future<void> updateBillPayment({
    required String billId,
    required double newPaidAmount,
    required double totalAmount,
  });

  /// Persists cloud PDF URL on the bill row.
  Future<void> updatePdfUrl({
    required String billId,
    required String pdfUrl,
    required DateTime pdfUpdatedAt,
  });

  /// Patches local-only bill metadata (e.g. display bill number).
  Future<void> patchLocalBillMetadata(
    String billId,
    Map<String, dynamic> fields,
  );

  /// Fetches a single bill by id (remote + local merge).
  Future<Bill?> fetchBillById(String billId);

  /// Reads the bill from local Hive only (no network).
  Future<Bill?> fetchLocalBillById(String billId);

  /// Bills linked to a customer id or phone.
  Stream<List<Bill>> watchBillsForCustomer({
    required String userId,
    String? customerId,
    String? customerPhone,
  });
}
