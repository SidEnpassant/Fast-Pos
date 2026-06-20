import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/receipt_payload.dart';
import 'package:inventopos/domain/repositories/printer_repository.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';

Future<void> printBillToBluetooth(BuildContext context, Bill bill) async {
  final profile = context.read<DashboardHubBloc>().state.profiles?.firstOrNull;
  final businessName = profile?.businessName ?? 'Store';
  final gstNumber = profile?.gstNumber;

  final payload = ReceiptPayload(
    businessName: businessName,
    customerName: bill.customerName,
    lines: bill.lineItems
        .map((l) => ReceiptLine(
              name: l.productName,
              quantity: l.quantity,
              total: l.totalPrice,
            ))
        .toList(),
    totalAmount: bill.totalAmount,
    paidAmount: bill.paidAmount,
    paymentMethod: bill.paymentMethod,
    gstNumber: gstNumber,
    billNumber: bill.displayBillNumber ?? bill.id.substring(0, 8),
  );

  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing receipt...')),
    );
    await context.read<PrinterRepository>().printReceipt(payload);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
