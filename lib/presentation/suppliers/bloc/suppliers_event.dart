part of 'suppliers_bloc.dart';

abstract class SuppliersEvent {}

class SuppliersStarted extends SuppliersEvent {
  final String userId;
  SuppliersStarted(this.userId);
}

class SuppliersReceived extends SuppliersEvent {
  final List<Supplier> suppliers;
  SuppliersReceived(this.suppliers);
}

class SuppliersSearchQueryChanged extends SuppliersEvent {
  final String query;
  SuppliersSearchQueryChanged(this.query);
}

class SupplierDeleted extends SuppliersEvent {
  final String id;
  SupplierDeleted(this.id);
}
