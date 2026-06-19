import 'package:inventopos/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Stream<List<Supplier>> watchSuppliersForUser(String userId);
  Future<Supplier> createSupplier(Supplier supplier);
  Future<Supplier> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
  Future<Supplier?> findById(String id);
  Future<List<Supplier>> searchSuppliers(String userId, String query);
}