import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/entities/purchase_order.dart';
import 'package:inventopos/domain/repositories/purchase_order_repository.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_event.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_state.dart';

class PurchaseOrderBloc extends Bloc<PurchaseOrderEvent, PurchaseOrderState> {
  final PurchaseOrderRepository _repository;
  StreamSubscription? _subscription;

  PurchaseOrderBloc(this._repository) : super(const PurchaseOrderState()) {
    on<PurchaseOrdersStarted>(_onStarted);
    on<PurchaseOrderCreated>(_onCreated);
    on<PurchaseOrderUpdated>(_onUpdated);
    on<PurchaseOrderReceived>(_onReceived);
    on<PurchaseOrderDeleted>(_onDeleted);
    on<_PurchaseOrdersUpdatedInternal>(_onInternalUpdate);
  }

  Future<void> _onStarted(PurchaseOrdersStarted event, Emitter<PurchaseOrderState> emit) async {
    emit(state.copyWith(status: PurchaseOrderStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchPurchaseOrdersForUser(event.userId).listen(
      (orders) {
        add(_PurchaseOrdersUpdatedInternal(orders));
      },
      onError: (e) {
        // Handle error if needed
      },
    );
  }

  // Internal event to handle stream updates
  void _onInternalUpdate(_PurchaseOrdersUpdatedInternal event, Emitter<PurchaseOrderState> emit) {
    emit(state.copyWith(
      status: PurchaseOrderStatus.success,
      orders: event.orders,
    ));
  }

  Future<void> _onCreated(PurchaseOrderCreated event, Emitter<PurchaseOrderState> emit) async {
    try {
      await _repository.createPurchaseOrder(event.order);
    } catch (e) {
      emit(state.copyWith(status: PurchaseOrderStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdated(PurchaseOrderUpdated event, Emitter<PurchaseOrderState> emit) async {
    try {
      await _repository.updatePurchaseOrder(event.order);
    } catch (e) {
      emit(state.copyWith(status: PurchaseOrderStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onReceived(PurchaseOrderReceived event, Emitter<PurchaseOrderState> emit) async {
    try {
      await _repository.receivePurchaseOrder(event.orderId, event.receivedLines);
    } catch (e) {
      emit(state.copyWith(status: PurchaseOrderStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleted(PurchaseOrderDeleted event, Emitter<PurchaseOrderState> emit) async {
    try {
      await _repository.deletePurchaseOrder(event.orderId);
    } catch (e) {
      emit(state.copyWith(status: PurchaseOrderStatus.failure, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class _PurchaseOrdersUpdatedInternal extends PurchaseOrderEvent {
  final List<PurchaseOrder> orders;
  const _PurchaseOrdersUpdatedInternal(this.orders);

  @override
  List<Object?> get props => [orders];
}
