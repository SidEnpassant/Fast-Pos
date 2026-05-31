import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/presentation/customers/bloc/customer_detail_event.dart';
import 'package:inventopos/presentation/customers/bloc/customer_detail_state.dart';

class CustomerDetailBloc extends Bloc<CustomerDetailEvent, CustomerDetailState> {
  CustomerDetailBloc(this._customers, this._bills)
      : super(const CustomerDetailState()) {
    on<CustomerDetailStarted>(_onStarted);
    on<CustomerDetailCustomerLoaded>(_onCustomerLoaded);
    on<CustomerDetailBillsLoaded>(_onBillsLoaded);
  }

  final CustomerRepository _customers;
  final BillsRepository _bills;
  StreamSubscription<List<Bill>>? _billsSub;

  Future<void> _onStarted(
    CustomerDetailStarted event,
    Emitter<CustomerDetailState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final customer = await _customers.findById(event.customerId);
    add(CustomerDetailCustomerLoaded(customer));

    await _billsSub?.cancel();
    _billsSub = _bills
        .watchBillsForCustomer(
          userId: event.userId,
          customerId: event.customerId,
          customerPhone: customer?.phone,
        )
        .listen((bills) => add(CustomerDetailBillsLoaded(bills)));
  }

  void _onCustomerLoaded(
    CustomerDetailCustomerLoaded event,
    Emitter<CustomerDetailState> emit,
  ) {
    emit(state.copyWith(customer: event.customer));
  }

  void _onBillsLoaded(
    CustomerDetailBillsLoaded event,
    Emitter<CustomerDetailState> emit,
  ) {
    emit(state.copyWith(bills: event.bills, loading: false));
  }

  @override
  Future<void> close() {
    _billsSub?.cancel();
    return super.close();
  }
}
