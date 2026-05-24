import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/customers/upsert_customer_from_bill_use_case.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';

class _FakeCustomerRepo implements CustomerRepository {
  final List<Customer> customers = [];

  @override
  Future<Customer> createCustomer({
    required String userId,
    required String name,
    String? phone,
  }) async {
    final c = Customer(
      id: 'c1',
      userId: userId,
      name: name,
      phone: phone,
      updatedAt: DateTime.now(),
    );
    customers.add(c);
    return c;
  }

  @override
  Future<Customer?> findByPhone(String userId, String phone) async {
    final n = phone.replaceAll(RegExp(r'\s+'), '');
    for (final c in customers) {
      if ((c.phone ?? '').replaceAll(RegExp(r'\s+'), '') == n) return c;
    }
    return null;
  }

  @override
  Stream<List<Customer>> watchCustomersForUser(String userId) async* {
    yield customers;
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async => customer;

  @override
  Future<void> recordLedgerEntry({
    required String customerId,
    required String type,
    required double amount,
    String? billId,
    String? note,
  }) async {}

  @override
  Future<void> recordCreditPayment({
    required String customerId,
    required double amount,
  }) async {}
}

void main() {
  test('creates customer from bill phone and name', () async {
    final repo = _FakeCustomerRepo();
    final useCase = UpsertCustomerFromBillUseCase(repo);

    final result = await useCase(
      const UpsertCustomerFromBillInput(
        userId: 'u1',
        customerName: 'Raj',
        customerPhone: '98765 43210',
        paymentStatus: 'complete',
        paidAmount: 100,
        totalAmount: 100,
        billId: 'b1',
      ),
    );

    expect(result.customerId, 'c1');
    expect(repo.customers.length, 1);
    expect(repo.customers.first.name, 'Raj');
  });
}
