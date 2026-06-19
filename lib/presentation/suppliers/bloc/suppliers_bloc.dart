import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/entities/supplier.dart';
import 'package:inventopos/domain/repositories/supplier_repository.dart';

part 'suppliers_event.dart';
part 'suppliers_state.dart';

class SuppliersBloc extends Bloc<SuppliersEvent, SuppliersState> {
  final SupplierRepository _supplierRepository;
  StreamSubscription? _suppliersSubscription;

  SuppliersBloc(this._supplierRepository) : super(const SuppliersState()) {
    on<SuppliersStarted>(_onStarted);
    on<SuppliersReceived>(_onReceived);
    on<SuppliersSearchQueryChanged>(_onSearchQueryChanged);
    on<SupplierDeleted>(_onDeleted);
  }

  Future<void> _onStarted(SuppliersStarted event, Emitter<SuppliersState> emit) async {
    emit(state.copyWith(loading: true));
    await _suppliersSubscription?.cancel();
    _suppliersSubscription = _supplierRepository
        .watchSuppliersForUser(event.userId)
        .listen((suppliers) => add(SuppliersReceived(suppliers)));
  }

  void _onReceived(SuppliersReceived event, Emitter<SuppliersState> emit) {
    emit(state.copyWith(
      allSuppliers: event.suppliers,
      filteredSuppliers: _filterSuppliers(event.suppliers, state.searchQuery),
      loading: false,
    ));
  }

  void _onSearchQueryChanged(SuppliersSearchQueryChanged event, Emitter<SuppliersState> emit) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredSuppliers: _filterSuppliers(state.allSuppliers, event.query),
    ));
  }

  Future<void> _onDeleted(SupplierDeleted event, Emitter<SuppliersState> emit) async {
    await _supplierRepository.deleteSupplier(event.id);
  }

  List<Supplier> _filterSuppliers(List<Supplier> suppliers, String query) {
    if (query.isEmpty) return suppliers;
    final lowercaseQuery = query.toLowerCase();
    return suppliers.where((s) {
      return s.name.toLowerCase().contains(lowercaseQuery) ||
          (s.phone?.contains(query) ?? false) ||
          (s.email?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (s.gstin?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  @override
  Future<void> close() {
    _suppliersSubscription?.cancel();
    return super.close();
  }
}
