import 'package:inventopos/domain/repositories/bills_repository.dart';

class DeleteBillUseCase {
  const DeleteBillUseCase(this._bills);

  final BillsRepository _bills;

  Future<void> call(String billId) => _bills.deleteBillById(billId);
}
