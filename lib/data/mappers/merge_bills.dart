import 'package:inventopos/domain/entities/bill.dart';

/// Merges remote and local bill snapshots (newest payment/pdf wins).
Bill mergeBillSnapshots(Bill remote, Bill local) {
  final remotePdf = remote.pdfUrl;
  final localPdf = local.pdfUrl;
  final remotePdfAt = remote.pdfUpdatedAt;
  final localPdfAt = local.pdfUpdatedAt;
  final preferLocalPdf = localPdfAt != null &&
      (remotePdfAt == null || !localPdfAt.isBefore(remotePdfAt));
  final pdfUrl = preferLocalPdf
      ? (localPdf ?? remotePdf)
      : (remotePdf ?? localPdf);
  final pdfUpdatedAt = preferLocalPdf ? localPdfAt : remotePdfAt;

  final remoteUpdated = remote.lastUpdated;
  final localUpdated = local.lastUpdated;
  final preferLocalPayment = localUpdated != null &&
      (remoteUpdated == null || !localUpdated.isBefore(remoteUpdated));

  return Bill(
    id: remote.id,
    userId: remote.userId ?? local.userId,
    businessName: remote.businessName ?? local.businessName,
    customerName: remote.customerName,
    customerPhone: remote.customerPhone,
    totalAmount: remote.totalAmount,
    paidAmount: preferLocalPayment ? local.paidAmount : remote.paidAmount,
    paymentMethod: remote.paymentMethod,
    paymentStatus:
        preferLocalPayment ? local.paymentStatus : remote.paymentStatus,
    createdAt: remote.createdAt,
    lastUpdated: preferLocalPayment ? local.lastUpdated : remote.lastUpdated,
    signedBillUrl: remote.signedBillUrl ?? local.signedBillUrl,
    lastSignedBillUpdate:
        remote.lastSignedBillUpdate ?? local.lastSignedBillUpdate,
    pdfUrl: pdfUrl,
    pdfUpdatedAt: pdfUpdatedAt ?? localPdfAt ?? remotePdfAt,
    displayBillNumber: remote.displayBillNumber ?? local.displayBillNumber,
    customerId: remote.customerId ?? local.customerId,
    lineItems: remote.lineItems.isNotEmpty ? remote.lineItems : local.lineItems,
  );
}
