import 'package:equatable/equatable.dart';

class CreditNoteLine extends Equatable {
  const CreditNoteLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.gstAmount = 0.0,
  });

  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final double gstAmount;

  @override
  List<Object?> get props => [
        productId,
        productName,
        quantity,
        unitPrice,
        lineTotal,
        gstAmount,
      ];
}

class CreditNote extends Equatable {
  const CreditNote({
    required this.id,
    required this.userId,
    required this.originalBillId,
    required this.creditNoteNumber,
    this.customerId,
    required this.customerName,
    required this.returnDate,
    required this.totalRefundAmount,
    required this.refundMethod,
    required this.status,
    required this.lineItems,
    this.reason,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String originalBillId;
  final String creditNoteNumber;
  final String? customerId;
  final String customerName;
  final DateTime returnDate;
  final double totalRefundAmount;
  final String refundMethod; // cash, credit, adjustment
  final String status; // draft, issued, applied
  final List<CreditNoteLine> lineItems;
  final String? reason;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        originalBillId,
        creditNoteNumber,
        customerId,
        customerName,
        returnDate,
        totalRefundAmount,
        refundMethod,
        status,
        lineItems,
        reason,
        createdAt,
      ];
}
