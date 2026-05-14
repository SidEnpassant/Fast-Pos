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
  });

  final String customerName;
  final String customerPhone;
  final List<BillDraftLine> lines;
  final String paymentMethod;
  final String paymentStatus;
  final double paidAmount;

  double get totalAmount =>
      lines.fold<double>(0, (s, e) => s + e.price * e.quantity);

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
