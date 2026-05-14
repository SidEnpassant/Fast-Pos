import 'package:inventopos/domain/repositories/bills_repository.dart';

class ReplaceSignedBillUseCase {
  const ReplaceSignedBillUseCase(this._bills);

  final BillsRepository _bills;

  Future<void> call({
    required String billId,
    required String localFilePath,
  }) =>
      _bills.replaceSignedBillFromLocalFile(
        billId: billId,
        localFilePath: localFilePath,
      );
}
