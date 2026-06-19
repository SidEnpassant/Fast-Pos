import 'package:equatable/equatable.dart';

/// Single line on a bill (from stored products JSON).
class BillLineItem extends Equatable {
  const BillLineItem({
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    this.productId,
    this.gstPercent,
    this.hsnCode,
    this.taxAmount = 0.0,
    this.uom = 'piece',
  });

  final String productName;
  final double quantity;
  final double totalPrice;
  final String? productId;
  final double? gstPercent;
  final String? hsnCode;
  final double taxAmount;
  final String uom;

  @override
  List<Object?> get props => [
        productName,
        quantity,
        totalPrice,
        productId,
        gstPercent,
        hsnCode,
        taxAmount,
        uom,
      ];
}

/// Bill aggregate for lists, dashboard, and analytics.
class Bill extends Equatable {
  const Bill({
    required this.id,
    this.userId,
    this.businessName,
    required this.customerName,
    required this.customerPhone,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.lastUpdated,
    this.signedBillUrl,
    this.lastSignedBillUpdate,
    this.pdfUrl,
    this.pdfUpdatedAt,
    this.displayBillNumber,
    this.customerId,
    required this.lineItems,
    this.taxAmount = 0.0,
    this.invoiceType = 'tax_invoice',
  });

  final String id;
  final String? userId;
  final String? businessName;
  final String customerName;
  final String customerPhone;
  final double totalAmount;
  final double paidAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final String? signedBillUrl;
  final DateTime? lastSignedBillUpdate;
  final String? pdfUrl;
  final DateTime? pdfUpdatedAt;
  final String? displayBillNumber;
  final String? customerId;
  final List<BillLineItem> lineItems;
  final double taxAmount;
  final String? invoiceType;

  @override
  List<Object?> get props => [
        id,
        userId,
        businessName,
        customerName,
        customerPhone,
        totalAmount,
        paidAmount,
        paymentMethod,
        paymentStatus,
        createdAt,
        lastUpdated,
        signedBillUrl,
        lastSignedBillUpdate,
        pdfUrl,
        pdfUpdatedAt,
        displayBillNumber,
        customerId,
        lineItems,
        taxAmount,
        invoiceType,
      ];
}
