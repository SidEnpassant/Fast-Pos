import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';

class UpsertCustomerFromBillInput {
  const UpsertCustomerFromBillInput({
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.paymentStatus,
    required this.paidAmount,
    required this.totalAmount,
    required this.billId,
  });

  final String userId;
  final String customerName;
  final String customerPhone;
  final String paymentStatus;
  final double paidAmount;
  final double totalAmount;
  final String billId;
}

class UpsertCustomerFromBillResult {
  const UpsertCustomerFromBillResult({this.customerId});

  final String? customerId;
}

/// Creates or updates a customer from bill customer fields and records ledger.
class UpsertCustomerFromBillUseCase {
  UpsertCustomerFromBillUseCase(this._customers);

  final CustomerRepository _customers;

  Future<UpsertCustomerFromBillResult> call(
    UpsertCustomerFromBillInput input,
  ) async {
    final phone = _normalizePhone(input.customerPhone);
    final name = input.customerName.trim();
    if (name.isEmpty && phone.isEmpty) {
      return const UpsertCustomerFromBillResult();
    }

    Customer? existing;
    if (phone.isNotEmpty) {
      existing = await _customers.findByPhone(input.userId, phone);
    }

    Customer customer;
    if (existing != null) {
      customer = existing;
      if (name.isNotEmpty && name != existing.name) {
        customer = await _customers.updateCustomer(
          Customer(
            id: existing.id,
            userId: existing.userId,
            name: name,
            phone: existing.phone ?? phone,
            creditBalance: existing.creditBalance,
            loyaltyPoints: existing.loyaltyPoints,
            updatedAt: DateTime.now(),
            syncStatus: existing.syncStatus,
          ),
        );
      }
    } else {
      customer = await _customers.createCustomer(
        userId: input.userId,
        name: name.isEmpty ? (phone.isEmpty ? 'Customer' : phone) : name,
        phone: phone.isEmpty ? null : phone,
      );
    }

    final status = input.paymentStatus.toLowerCase();
    if (status == 'credit' || status == 'partial') {
      final owed = input.totalAmount - input.paidAmount;
      if (owed > 0) {
        await _customers.recordLedgerEntry(
          customerId: customer.id,
          type: 'debit',
          amount: owed,
          billId: input.billId,
          note: 'Bill credit',
        );
      }
    }

    return UpsertCustomerFromBillResult(customerId: customer.id);
  }

  String _normalizePhone(String raw) =>
      raw.replaceAll(RegExp(r'\s+'), '').trim();
}
