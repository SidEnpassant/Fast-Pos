import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/product.dart';

sealed class BillInventoryPickerEvent extends Equatable {
  const BillInventoryPickerEvent();

  @override
  List<Object?> get props => [];
}

class BillInventoryPickerStarted extends BillInventoryPickerEvent {
  const BillInventoryPickerStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class BillInventoryPickerProductsReceived extends BillInventoryPickerEvent {
  const BillInventoryPickerProductsReceived(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

class BillInventoryPickerSearchChanged extends BillInventoryPickerEvent {
  const BillInventoryPickerSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
