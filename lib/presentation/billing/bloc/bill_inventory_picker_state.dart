import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/product.dart';

class BillInventoryPickerState extends Equatable {
  const BillInventoryPickerState({
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.loading = true,
  });

  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final String searchQuery;
  final bool loading;

  BillInventoryPickerState copyWith({
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    String? searchQuery,
    bool? loading,
  }) =>
      BillInventoryPickerState(
        allProducts: allProducts ?? this.allProducts,
        filteredProducts: filteredProducts ?? this.filteredProducts,
        searchQuery: searchQuery ?? this.searchQuery,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props =>
      [allProducts, filteredProducts, searchQuery, loading];
}
