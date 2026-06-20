import 'package:inventopos/application/billing/upload_bill_pdf_use_case.dart';
import 'package:inventopos/application/billing/validate_bill_draft_use_case.dart';
import 'package:inventopos/application/customers/upsert_customer_from_bill_use_case.dart';
import 'package:inventopos/application/daybook/record_cash_entry_use_case.dart';
import 'package:inventopos/application/inventory/decrement_stock_on_bill_use_case.dart';
import 'package:inventopos/application/inventory/update_product_velocity_use_case.dart';
import 'package:inventopos/application/loyalty/earn_loyalty_points_use_case.dart';
import 'package:inventopos/application/loyalty/redeem_loyalty_points_use_case.dart';
import 'package:inventopos/application/tax/compute_gst_for_bill_use_case.dart';
import 'package:inventopos/core/performance/main_isolate.dart';
import 'package:inventopos/data/billing/bill_pdf_generator.dart';
import 'package:inventopos/data/security/bill_audit_service.dart';
import 'package:inventopos/domain/billing/bill_submission.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/transactions_repository.dart';
import 'package:inventopos/domain/tax/gst_config.dart';

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
    this._updateVelocity,
    this._computeGst,
    this._recordCashEntry,
    this._earnLoyaltyPoints,
    this._redeemLoyaltyPoints,
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
  final UpdateProductVelocityUseCase _updateVelocity;
  final ComputeGstForBillUseCase _computeGst;
  final RecordCashEntryUseCase _recordCashEntry;
  final EarnLoyaltyPointsUseCase _earnLoyaltyPoints;
  final RedeemLoyaltyPointsUseCase _redeemLoyaltyPoints;

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

    // Compute GST if configured
    final gstConfig = GstConfig(
      businessGstin: merchant?.gstNumber,
      stateCode: merchant?.stateCode,
      isComposition: merchant?.isCompositionDealer ?? false,
    );

    // Assume intra-state for now unless we have customer state code
    final gstSummary = _computeGst(
      lines: draft.lines,
      config: gstConfig,
      isInterState: false,
    );

    // Embed tax breakdown into line items
    final enrichedLines = <Map<String, dynamic>>[];
    for (var i = 0; i < draft.lines.length; i++) {
      final line = draft.lines[i];
      final lineResult = gstSummary.lineResults[i];
      final lineJson = line.toProductsJson();

      if (lineResult.totalTaxAmount > 0) {
        lineJson['tax_amount'] = lineResult.totalTaxAmount;
        lineJson['cgst'] = lineResult.cgstAmount;
        lineJson['sgst'] = lineResult.sgstAmount;
        lineJson['igst'] = lineResult.igstAmount;
      }
      enrichedLines.add(lineJson);
    }

    final invoiceType = merchant?.isCompositionDealer == true
        ? 'bill_of_supply'
        : 'tax_invoice';
    final total = draft.totalAmount + gstSummary.totalTaxAmount;
    final paid = draft.paymentStatus == 'complete' ? total : draft.paidAmount;

    final auditPayload = {
      'customer': draft.customerName,
      'total': total,
      'lines': enrichedLines,
      'payment_status': draft.paymentStatus,
    };
    final contentHash = BillAuditService.hashPayload(auditPayload);

    final billId = await _bills.createBill(
      businessName: businessName,
      customerName: draft.customerName.trim(),
      customerPhone: draft.customerPhone.trim(),
      productsJson: enrichedLines,
      totalAmount: total,
      paidAmount: paid,
      paymentMethod: draft.paymentMethod,
      paymentStatus: draft.paymentStatus,
      customerId: draft.customerId,
      discountBreakdown: draft.discountBreakdown,
      contentHash: contentHash,
      // Need to add taxAmount and invoiceType to BillsRepository.createBill signature eventually
    );

    // Update tax metadata locally (assuming createBill will be updated to take these, but for now we can patch)
    await _bills.patchLocalBillMetadata(billId, {
      'tax_amount': gstSummary.totalTaxAmount,
      'invoice_type': invoiceType,
    });

    final uid = _auth.currentSession?.userId;
    if (uid != null) {
      await _decrementStock(
        billId: billId,
        lines: draft.lines,
        userId: uid,
      );
      await _updateVelocity(userId: uid, lines: draft.lines);

      // Record cash entry if payment method is cash
      if (draft.paymentMethod == 'cash' && paid > 0) {
        await _recordCashEntry(
          userId: uid,
          amount: paid,
          type: 'in',
          referenceId: billId,
          referenceType: 'bill',
          note: 'Payment for Bill #$billId',
        );
      }
    }

    String? resolvedCustomerId = draft.customerId;

    if (uid != null &&
        (draft.customerName.trim().isNotEmpty ||
            draft.customerPhone.trim().isNotEmpty)) {
      final upsertResult = await _upsertCustomer(
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
      resolvedCustomerId ??= upsertResult.customerId;
    }

    if (uid != null && resolvedCustomerId != null) {
      // 1. Redeem points if requested
      final loyaltyDiscountItem = draft.discountBreakdown?.where((d) => d['type'] == 'loyalty').firstOrNull;
      if (loyaltyDiscountItem != null) {
        final ptsRedeemed = (loyaltyDiscountItem['points_redeemed'] as num).toInt();
        await _redeemLoyaltyPoints(
          userId: uid,
          customerId: resolvedCustomerId,
          pointsToRedeem: ptsRedeemed,
        );
      }

      // 2. Earn points for the remaining subtotal (we construct a pseudo-bill object to satisfy signature)
      final dummyBillForLoyalty = Bill(
        id: billId,
        businessName: businessName,
        customerName: draft.customerName.trim(),
        customerPhone: draft.customerPhone.trim(),
        totalAmount: total, // or draft.totalAmount? EarnLoyalty uses totalAmount, which has discount applied!
        paidAmount: paid,
        paymentStatus: draft.paymentStatus,
        paymentMethod: draft.paymentMethod,
        lineItems: const [],
        createdAt: DateTime.now(),
      );

      await _earnLoyaltyPoints(
        userId: uid,
        customerId: resolvedCustomerId,
        bill: dummyBillForLoyalty,
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
      paidAmount: paid,
      totalAmount: total,
      discountBreakdown: draft.discountBreakdown,
      // We will need to pass gstSummary to the PDF generator later
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

    final bill = await _bills.fetchBillById(billId);
    if (bill == null) {
      throw StateError('Failed to fetch newly created bill');
    }

    return BillSubmissionResult(billId: billId, pdfPath: pdfPath, bill: bill);
  }
}
