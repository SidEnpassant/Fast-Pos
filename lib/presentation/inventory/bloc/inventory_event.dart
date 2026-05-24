import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_state.dart';

sealed class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

final class InventoryStarted extends InventoryEvent {
  const InventoryStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class InventoryProductsReceived extends InventoryEvent {
  const InventoryProductsReceived(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

final class InventorySearchQueryChanged extends InventoryEvent {
  const InventorySearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class InventoryProductSaved extends InventoryEvent {
  const InventoryProductSaved(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

final class InventoryProductDeleted extends InventoryEvent {
  const InventoryProductDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class InventoryFilterChanged extends InventoryEvent {
  const InventoryFilterChanged(this.filter);

  final InventoryFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class InventorySortChanged extends InventoryEvent {
  const InventorySortChanged(this.sort);

  final InventorySort sort;

  @override
  List<Object?> get props => [sort];
}

final class InventoryViewModeChanged extends InventoryEvent {
  const InventoryViewModeChanged(this.mode);

  final InventoryViewMode mode;

  @override
  List<Object?> get props => [mode];
}

final class InventoryCategoryFilterChanged extends InventoryEvent {
  const InventoryCategoryFilterChanged(this.category);

  final String? category;

  @override
  List<Object?> get props => [category];
}
