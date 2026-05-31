import 'package:inventopos/application/billing/regenerate_and_upload_bill_pdf_use_case.dart';
import 'package:inventopos/domain/billing/bill_payment_snapshot.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';

/// Result of updating bill payment — payment always commits before PDF sync.
class UpdateBillPaymentResult {
  const UpdateBillPaymentResult({
    required this.paymentUpdated,
    this.pdfUrl,
    this.pdfSyncFailed = false,
    this.pdfErrorMessage,
  });

  final bool paymentUpdated;
  final String? pdfUrl;
  final bool pdfSyncFailed;
  final String? pdfErrorMessage;
}

class UpdateBillPaymentUseCase {
  const UpdateBillPaymentUseCase(
    this._bills,
    this._regeneratePdf,
  );

  final BillsRepository _bills;
  final RegenerateAndUploadBillPdfUseCase _regeneratePdf;

  static const _pdfRetryDelaysMs = [400, 800, 1200];

  Future<UpdateBillPaymentResult> call({
    required String billId,
    required double newPaidAmount,
    required double totalAmount,
  }) async {
    final paymentStatus =
        newPaidAmount >= totalAmount ? 'complete' : 'partial';
    final updatedAt = DateTime.now();

    await _bills.updateBillPayment(
      billId: billId,
      newPaidAmount: newPaidAmount,
      totalAmount: totalAmount,
    );

    final paymentSnapshot = BillPaymentSnapshot(
      paidAmount: newPaidAmount,
      paymentStatus: paymentStatus,
      totalAmount: totalAmount,
      updatedAt: updatedAt,
    );

    Object? lastError;
    for (var attempt = 0; attempt <= _pdfRetryDelaysMs.length; attempt++) {
      try {
        final pdfUrl = await _regeneratePdf(
          billId,
          paymentOverride: paymentSnapshot,
        );
        if (pdfUrl.isNotEmpty) {
          return UpdateBillPaymentResult(
            paymentUpdated: true,
            pdfUrl: pdfUrl,
          );
        }
        lastError = StateError('PDF upload returned empty URL');
      } catch (e) {
        lastError = e;
      }

      if (attempt < _pdfRetryDelaysMs.length) {
        await Future<void>.delayed(
          Duration(milliseconds: _pdfRetryDelaysMs[attempt]),
        );
      }
    }

    return UpdateBillPaymentResult(
      paymentUpdated: true,
      pdfSyncFailed: true,
      pdfErrorMessage: lastError?.toString(),
    );
  }
}
