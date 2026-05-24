import 'package:inventopos/application/customers/upsert_customer_from_bill_use_case.dart';
import 'package:inventopos/core/performance/main_isolate.dart';
import 'package:inventopos/data/billing/bill_pdf_generator.dart';
import 'package:inventopos/data/security/bill_audit_service.dart';
import 'package:inventopos/domain/billing/bill_submission.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/transactions_repository.dart';

/// Persists bill + transaction, then generates the PDF on disk.
class SubmitBillUseCase {
  SubmitBillUseCase(
    this._bills,
    this._profile,
    this._transactions,
    this._pdf,
    this._auth,
    this._upsertCustomer,
  );

  final BillsRepository _bills;
  final ProfileRepository _profile;
  final TransactionsRepository _transactions;
  final BillPdfGenerator _pdf;
  final AuthRepository _auth;
  final UpsertCustomerFromBillUseCase _upsertCustomer;

  Future<BillSubmissionResult> call(BillSubmissionDraft draft) async {
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

    return BillSubmissionResult(billId: billId, pdfPath: pdfPath);
  }
}
