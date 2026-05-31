/// Authoritative payment fields for PDF regeneration after an update.
class BillPaymentSnapshot {
  const BillPaymentSnapshot({
    required this.paidAmount,
    required this.paymentStatus,
    required this.totalAmount,
    required this.updatedAt,
  });

  final double paidAmount;
  final String paymentStatus;
  final double totalAmount;
  final DateTime updatedAt;
}
