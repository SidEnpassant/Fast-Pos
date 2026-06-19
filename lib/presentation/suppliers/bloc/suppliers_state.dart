part of 'suppliers_bloc.dart';

class SuppliersState {
  final List<Supplier> allSuppliers;
  final List<Supplier> filteredSuppliers;
  final bool loading;
  final String searchQuery;

  const SuppliersState({
    this.allSuppliers = const [],
    this.filteredSuppliers = const [],
    this.loading = false,
    this.searchQuery = '',
  });

  SuppliersState copyWith({
    List<Supplier>? allSuppliers,
    List<Supplier>? filteredSuppliers,
    bool? loading,
    String? searchQuery,
  }) {
    return SuppliersState(
      allSuppliers: allSuppliers ?? this.allSuppliers,
      filteredSuppliers: filteredSuppliers ?? this.filteredSuppliers,
      loading: loading ?? this.loading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
