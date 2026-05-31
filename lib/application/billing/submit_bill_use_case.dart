import 'package:inventopos/application/billing/upload_bill_pdf_use_case.dart';
import 'package:inventopos/application/customers/upsert_customer_from_bill_use_case.dart';
import 'package:inventopos/application/billing/validate_bill_draft_use_case.dart';
import 'package:inventopos/application/inventory/decrement_stock_on_bill_use_case.dart';
import 'package:inventopos/core/performance/main_isolate.dart';
import 'package:inventopos/data/billing/bill_pdf_generator.dart';
import 'package:inventopos/data/security/bill_audit_service.dart';
import 'package:inventopos/domain/billing/bill_submission.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/transactions_repository.dart';

/// Persists bill, decrements stock, generates PDF, uploads to cloud.
class SubmitBillUseCase {
  SubmitBillUseCase(
    this._bills,
    this._profile,
    this._transactions,
    this._pdf,
    this._auth,
    this._upsertCustomer,
    this._validateDraft,
    this._decrementStock,
    this._uploadPdf,
  );

  final BillsRepository _bills;
  final ProfileRepository _profile;
  final TransactionsRepository _transactions;
  final BillPdfGenerator _pdf;
  final AuthRepository _auth;
  final UpsertCustomerFromBillUseCase _upsertCustomer;
  final ValidateBillDraftUseCase _validateDraft;
  final DecrementStockOnBillUseCase _decrementStock;
  final UploadBillPdfUseCase _uploadPdf;

  Future<BillSubmissionResult> call(BillSubmissionDraft draft) async {
    final validationError = await _validateDraft(draft.lines);
    if (validationError != null) {
      throw StateError(validationError);
    }

    final merchant = await _profile.fetchCurrentUserProfileSnapshot();
    final businessName = merchant?.businessName;
    if (businessName == null || businessName.isEmpty) {
      throw StateError('Business name not found');
    }

    final productsJson = draft.lines.map((e) => e.toProductsJson()).toList();
    final total = draft.totalAmount;
    final paid = draft.effectivePaidAmount;

    final auditPayload = {
      'customer': draft.customerName,
      'total': total,
      'lines': productsJson,
      'payment_status': draft.paymentStatus,
    };
    final contentHash = BillAuditService.hashPayload(auditPayload);

    final billId = await _bills.createBill(
      businessName: businessName,
      customerName: draft.customerName.trim(),
      customerPhone: draft.customerPhone.trim(),
      productsJson: productsJson,
      totalAmount: total,
      paidAmount: paid,
      paymentMethod: draft.paymentMethod,
      paymentStatus: draft.paymentStatus,
      customerId: draft.customerId,
      discountBreakdown: draft.discountBreakdown,
      contentHash: contentHash,
    );

    final uid = _auth.currentSession?.userId;
    if (uid != null) {
      await _decrementStock(
        billId: billId,
        lines: draft.lines,
        userId: uid,
      );
    }

    if (uid != null &&
        (draft.customerName.trim().isNotEmpty ||
            draft.customerPhone.trim().isNotEmpty)) {
      await _upsertCustomer(
        UpsertCustomerFromBillInput(
          userId: uid,
          customerName: draft.customerName.trim(),
          customerPhone: draft.customerPhone.trim(),
          paymentStatus: draft.paymentStatus,
          paidAmount: paid,
          totalAmount: total,
          billId: billId,
        ),
      );
    }

    final txAmount =
        draft.paymentStatus == 'complete' ? total : draft.paidAmount;
    await _transactions.recordBillTransaction(
      customerName: draft.customerName.trim(),
      amount: txAmount,
      isComplete: draft.paymentStatus == 'complete',
    );

    final sequentialBillNumber = await _bills.nextBillSequenceNumber();
    await _bills.patchLocalBillMetadata(billId, {
      'display_bill_number': sequentialBillNumber,
    });

    await deferToNextEventLoop(() async {});

    final m = merchant!;
    final pdfPath = await _pdf.writeToApplicationDocuments(
      billId: billId,
      sequentialBillNumber: sequentialBillNumber,
      merchant: m,
      customerName: draft.customerName.trim(),
      customerPhone: draft.customerPhone.trim(),
      lines: draft.lines,
      paymentMethod: draft.paymentMethod,
      paymentStatus: draft.paymentStatus,
      paidAmount: draft.paidAmount,
      totalAmount: total,
    );

    try {
      await _uploadPdf(
        billId: billId,
        localPdfPath: pdfPath,
      );
    } catch (_) {
      for (final delayMs in [600, 1200, 2000]) {
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        try {
          await _uploadPdf(
            billId: billId,
            localPdfPath: pdfPath,
          );
          break;
        } catch (_) {}
      }
    }

    return BillSubmissionResult(billId: billId, pdfPath: pdfPath);
  }
}
