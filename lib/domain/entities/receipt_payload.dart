import 'package:equatable/equatable.dart';

class ReceiptLine extends Equatable {
  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String name;
  final int quantity;
  final double total;

  @override
  List<Object?> get props => [name, quantity, total];
}

class ReceiptPayload extends Equatable {
  const ReceiptPayload({
    required this.businessName,
    required this.customerName,
    required this.lines,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMethod,
    this.gstNumber,
    this.billNumber,
  });

  final String businessName;
  final String customerName;
  final List<ReceiptLine> lines;
  final double totalAmount;
  final double paidAmount;
  final String paymentMethod;
  final String? gstNumber;
  final String? billNumber;

  @override
  List<Object?> get props => [
        businessName,
        customerName,
        lines,
        totalAmount,
        paidAmount,
        paymentMethod,
        gstNumber,
        billNumber,
      ];
}
