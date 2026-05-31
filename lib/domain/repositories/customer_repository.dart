import 'package:inventopos/domain/entities/customer.dart';

abstract class CustomerRepository {
  Stream<List<Customer>> watchCustomersForUser(String userId);

  Future<Customer?> findByPhone(String userId, String phone);

  Future<Customer?> findById(String customerId);

  Future<Customer> createCustomer({
    required String userId,
    required String name,
    String? phone,
  });

  Future<Customer> updateCustomer(Customer customer);

  Future<void> recordLedgerEntry({
    required String customerId,
    required String type,
    required double amount,
    String? billId,
    String? note,
  });

  Future<void> recordCreditPayment({
    required String customerId,
    required double amount,
  });
}
