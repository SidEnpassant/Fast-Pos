import 'package:equatable/equatable.dart';

/// Single line on a bill (from stored products JSON).
class BillLineItem extends Equatable {
  const BillLineItem({
    required this.productName,
    required this.quantity,
    required this.totalPrice,
  });

  final String productName;
  final int quantity;
  final double totalPrice;

  @override
  List<Object?> get props => [productName, quantity, totalPrice];
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
    required this.lineItems,
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
  final List<BillLineItem> lineItems;

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
        lineItems,
      ];
}
