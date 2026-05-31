import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';

sealed class CustomerDetailEvent extends Equatable {
  const CustomerDetailEvent();
  @override
  List<Object?> get props => [];
}

class CustomerDetailStarted extends CustomerDetailEvent {
  const CustomerDetailStarted({
    required this.userId,
    required this.customerId,
  });

  final String userId;
  final String customerId;

  @override
  List<Object?> get props => [userId, customerId];
}

class CustomerDetailCustomerLoaded extends CustomerDetailEvent {
  const CustomerDetailCustomerLoaded(this.customer);
  final Customer? customer;
  @override
  List<Object?> get props => [customer];
}

class CustomerDetailBillsLoaded extends CustomerDetailEvent {
  const CustomerDetailBillsLoaded(this.bills);
  final List<Bill> bills;
  @override
  List<Object?> get props => [bills];
}
