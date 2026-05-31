import 'package:inventopos/application/billing/upload_bill_pdf_use_case.dart';
import 'package:inventopos/data/billing/bill_pdf_generator.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/billing/bill_payment_snapshot.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';

/// Regenerates invoice PDF after payment update and uploads to cloud storage.
class RegenerateAndUploadBillPdfUseCase {
  RegenerateAndUploadBillPdfUseCase(
    this._bills,
    this._profile,
    this._pdf,
    this._upload,
  );

  final BillsRepository _bills;
  final ProfileRepository _profile;
  final BillPdfGenerator _pdf;
  final UploadBillPdfUseCase _upload;

  Future<String> call(
    String billId, {
    BillPaymentSnapshot? paymentOverride,
  }) async {
    final bill = await _loadBillForRegeneration(billId);
    if (bill == null) {
      throw StateError('Bill not found for PDF regeneration');
    }

    final merchant = await _profile.fetchCurrentUserProfileSnapshot();
    if (merchant == null) {
      throw StateError('Merchant profile not found');
    }

    final paidAmount = paymentOverride?.paidAmount ?? bill.paidAmount;
    final paymentStatus =
        paymentOverride?.paymentStatus ?? bill.paymentStatus;
    final totalAmount = paymentOverride?.totalAmount ?? bill.totalAmount;
    final updatedAt =
        paymentOverride?.updatedAt ?? bill.lastUpdated ?? DateTime.now();

    final seq = bill.displayBillNumber ?? bill.id.substring(0, 8);
    final lines = bill.lineItems
        .map(
          (l) => BillDraftLine(
            name: l.productName,
            price: l.quantity > 0 ? l.totalPrice / l.quantity : l.totalPrice,
            quantity: l.quantity,
          ),
        )
        .toList();

    final localPath = await _pdf.writeToApplicationDocuments(
      billId: bill.id,
      sequentialBillNumber: seq,
      merchant: merchant,
      customerName: bill.customerName,
      customerPhone: bill.customerPhone,
      lines: lines,
      paymentMethod: bill.paymentMethod,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      totalAmount: totalAmount,
      updatedAt: updatedAt,
    );

    return _upload(
      billId: billId,
      localPdfPath: localPath,
      previousPdfUrl: bill.pdfUrl,
    );
  }

  Future<Bill?> _loadBillForRegeneration(String billId) async {
    final local = await _bills.fetchLocalBillById(billId);
    if (local != null) return local;
    return _bills.fetchBillById(billId);
  }
}
