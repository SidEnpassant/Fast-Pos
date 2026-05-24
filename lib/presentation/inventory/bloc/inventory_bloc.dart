import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_event.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc(this._products) : super(const InventoryState()) {
    on<InventoryStarted>(_onStarted);
    on<InventoryProductsReceived>(_onProductsReceived);
    on<InventorySearchQueryChanged>(_onSearchChanged);
    on<InventoryProductSaved>(_onProductSaved);
    on<InventoryProductDeleted>(_onProductDeleted);
    on<InventoryFilterChanged>(_onFilterChanged);
    on<InventorySortChanged>(_onSortChanged);
    on<InventoryViewModeChanged>(_onViewModeChanged);
    on<InventoryCategoryFilterChanged>(_onCategoryChanged);
  }

  final ProductRepository _products;
  StreamSubscription<dynamic>? _sub;
  String? _userId;

  Future<void> _onStarted(
    InventoryStarted event,
    Emitter<InventoryState> emit,
  ) async {
    _userId = event.userId;
    await _sub?.cancel();
    _sub = _products.watchProductsForUser(event.userId).listen(
          (list) => add(InventoryProductsReceived(list)),
        );
  }

  void _onProductsReceived(
    InventoryProductsReceived event,
    Emitter<InventoryState> emit,
  ) {
    emit(
      state.copyWith(
        allProducts: event.products,
        filteredProducts: _apply(event.products, state),
        loading: false,
      ),
    );
  }

  Future<void> _onSearchChanged(
    InventorySearchQueryChanged event,
    Emitter<InventoryState> emit,
  ) async {
    final q = event.query;
    if (_userId == null) return;
    List<Product> base;
    if (q.isEmpty) {
      base = state.allProducts;
    } else {
      base = await _products.searchProducts(_userId!, q);
    }
    emit(
      state.copyWith(
        searchQuery: q,
        filteredProducts: _apply(base, state.copyWith(searchQuery: q)),
      ),
    );
  }

  void _onFilterChanged(
    InventoryFilterChanged event,
    Emitter<InventoryState> emit,
  ) {
    emit(
      state.copyWith(
        filter: event.filter,
        filteredProducts: _apply(state.allProducts, state.copyWith(filter: event.filter)),
      ),
    );
  }

  void _onSortChanged(
    InventorySortChanged event,
    Emitter<InventoryState> emit,
  ) {
    emit(
      state.copyWith(
        sort: event.sort,
        filteredProducts: _apply(state.allProducts, state.copyWith(sort: event.sort)),
      ),
    );
  }

  void _onViewModeChanged(
    InventoryViewModeChanged event,
    Emitter<InventoryState> emit,
  ) {
    emit(state.copyWith(viewMode: event.mode));
  }

  void _onCategoryChanged(
    InventoryCategoryFilterChanged event,
    Emitter<InventoryState> emit,
  ) {
    emit(
      state.copyWith(
        categoryFilter: event.category,
        clearCategory: event.category == null,
        filteredProducts: _apply(
          state.allProducts,
          state.copyWith(
            categoryFilter: event.category,
            clearCategory: event.category == null,
          ),
        ),
      ),
    );
  }

  Future<void> _onProductSaved(
    InventoryProductSaved event,
    Emitter<InventoryState> emit,
  ) async {
    if (_userId == null) return;
    await _products.updateProduct(event.product);
  }

  Future<void> _onProductDeleted(
    InventoryProductDeleted event,
    Emitter<InventoryState> emit,
  ) async {
    await _products.deleteProduct(event.id);
  }

  List<Product> _apply(List<Product> products, InventoryState s) {
    var list = products.where((p) => p.isActive || p.deletedAt == null).toList();

    if (s.searchQuery.isNotEmpty) {
      final lower = s.searchQuery.toLowerCase();
      list = list
          .where((p) => p.name.toLowerCase().contains(lower))
          .toList();
    }

    switch (s.filter) {
      case InventoryFilter.lowStock:
        list = list.where((p) => p.isLowStock).toList();
      case InventoryFilter.outOfStock:
        list = list.where((p) => p.stockQuantity <= 0).toList();
      case InventoryFilter.all:
        break;
    }

    if (s.categoryFilter != null) {
      list = list.where((p) => p.category == s.categoryFilter).toList();
    }

    switch (s.sort) {
      case InventorySort.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
      case InventorySort.stockAsc:
        list.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
      case InventorySort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case InventorySort.updatedDesc:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return list;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
