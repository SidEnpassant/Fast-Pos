import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/presentation/billing/bloc/bill_inventory_picker_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_inventory_picker_state.dart';

class BillInventoryPickerBloc
    extends Bloc<BillInventoryPickerEvent, BillInventoryPickerState> {
  BillInventoryPickerBloc(this._products)
      : super(const BillInventoryPickerState()) {
    on<BillInventoryPickerStarted>(_onStarted);
    on<BillInventoryPickerProductsReceived>(_onProductsReceived);
    on<BillInventoryPickerSearchChanged>(_onSearchChanged);
  }

  final ProductRepository _products;
  StreamSubscription<List<Product>>? _sub;
  String? _userId;

  Future<void> _onStarted(
    BillInventoryPickerStarted event,
    Emitter<BillInventoryPickerState> emit,
  ) async {
    _userId = event.userId;
    await _sub?.cancel();
    _sub = _products.watchProductsForUser(event.userId).listen(
          (list) => add(BillInventoryPickerProductsReceived(list)),
        );
  }

  void _onProductsReceived(
    BillInventoryPickerProductsReceived event,
    Emitter<BillInventoryPickerState> emit,
  ) {
    final active = event.products.where((p) => p.isActive).toList();
    emit(
      state.copyWith(
        allProducts: active,
        filteredProducts: _filter(active, state.searchQuery),
        loading: false,
      ),
    );
  }

  Future<void> _onSearchChanged(
    BillInventoryPickerSearchChanged event,
    Emitter<BillInventoryPickerState> emit,
  ) async {
    final q = event.query.trim().toLowerCase();
    if (_userId == null) return;
    List<Product> base;
    if (q.isEmpty) {
      base = state.allProducts;
    } else {
      base = await _products.searchProducts(_userId!, q);
    }
    emit(
      state.copyWith(
        searchQuery: event.query,
        filteredProducts: _filter(base, q),
      ),
    );
  }

  List<Product> _filter(List<Product> products, String q) {
    if (q.isEmpty) return products;
    final lower = q.toLowerCase();
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(lower) ||
              (p.barcode?.toLowerCase().contains(lower) ?? false) ||
              (p.sku?.toLowerCase().contains(lower) ?? false),
        )
        .toList();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
