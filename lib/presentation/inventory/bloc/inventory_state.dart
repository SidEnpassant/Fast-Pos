import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/product.dart';

enum InventoryFilter { all, lowStock, outOfStock }

enum InventorySort { nameAsc, stockAsc, priceDesc, updatedDesc }

enum InventoryViewMode { list, grid }

class InventoryState extends Equatable {
  const InventoryState({
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.loading = true,
    this.filter = InventoryFilter.all,
    this.sort = InventorySort.nameAsc,
    this.viewMode = InventoryViewMode.list,
    this.categoryFilter,
  });

  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final String searchQuery;
  final bool loading;
  final InventoryFilter filter;
  final InventorySort sort;
  final InventoryViewMode viewMode;
  final String? categoryFilter;

  List<Product> get lowStockProducts =>
      allProducts.where((p) => p.isLowStock).toList();

  List<String> get categories {
    final set = <String>{};
    for (final p in allProducts) {
      if (p.category != null && p.category!.isNotEmpty) set.add(p.category!);
    }
    return set.toList()..sort();
  }

  InventoryState copyWith({
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    String? searchQuery,
    bool? loading,
    InventoryFilter? filter,
    InventorySort? sort,
    InventoryViewMode? viewMode,
    String? categoryFilter,
    bool clearCategory = false,
  }) {
    return InventoryState(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      loading: loading ?? this.loading,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      viewMode: viewMode ?? this.viewMode,
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
    );
  }

  @override
  List<Object?> get props => [
        allProducts,
        filteredProducts,
        searchQuery,
        loading,
        filter,
        sort,
        viewMode,
        categoryFilter,
      ];
}
