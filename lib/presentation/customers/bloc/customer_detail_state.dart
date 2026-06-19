import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';

class CustomerDetailState extends Equatable {
  const CustomerDetailState({
    this.customer,
    this.bills = const [],
    this.loading = true,
  });

  final Customer? customer;
  final List<Bill> bills;
  final bool loading;

  double get totalSpent => bills.fold(0.0, (s, b) => s + b.totalAmount);

  CustomerDetailState copyWith({
    Customer? customer,
    List<Bill>? bills,
    bool? loading,
  }) =>
      CustomerDetailState(
        customer: customer ?? this.customer,
        bills: bills ?? this.bills,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [customer, bills, loading];
}
