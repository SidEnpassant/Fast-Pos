import 'package:inventopos/domain/repositories/bills_repository.dart';

class UpdateBillPaymentUseCase {
  const UpdateBillPaymentUseCase(this._bills);

  final BillsRepository _bills;

  Future<void> call({
    required String billId,
    required double newPaidAmount,
    required double totalAmount,
  }) =>
      _bills.updateBillPayment(
        billId: billId,
        newPaidAmount: newPaidAmount,
        totalAmount: totalAmount,
      );
}
