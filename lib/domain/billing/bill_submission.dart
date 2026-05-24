import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';

/// Customer + lines + payment snapshot for creating a bill (domain input).
class BillSubmissionDraft extends Equatable {
  const BillSubmissionDraft({
    required this.customerName,
    required this.customerPhone,
    required this.lines,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAmount,
    this.customerId,
    this.discountBreakdown,
    this.discountTotal = 0,
  });

  final String customerName;
  final String customerPhone;
  final List<BillDraftLine> lines;
  final String paymentMethod;
  final String paymentStatus;
  final double paidAmount;
  final String? customerId;
  final List<Map<String, dynamic>>? discountBreakdown;
  final double discountTotal;

  double get totalAmount {
    final subtotal =
        lines.fold<double>(0, (s, e) => s + e.price * e.quantity);
    return subtotal - discountTotal;
  }

  double get effectivePaidAmount =>
      paymentStatus == 'complete' ? totalAmount : paidAmount;

  @override
  List<Object?> get props => [
        customerName,
        customerPhone,
        lines,
        paymentMethod,
        paymentStatus,
        paidAmount,
        customerId,
        discountBreakdown,
        discountTotal,
      ];
}

class BillSubmissionResult extends Equatable {
  const BillSubmissionResult({
    required this.billId,
    required this.pdfPath,
  });

  final String billId;
  final String pdfPath;

  @override
  List<Object?> get props => [billId, pdfPath];
}
