import '../../domain/entities/bill.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/repositories/credit_note_repository.dart';
import '../../domain/returns/return_policy.dart';

class ProcessReturnUseCase {
  ProcessReturnUseCase(this._creditNotes);

  final CreditNoteRepository _creditNotes;

  Future<CreditNote> call({
    required Bill originalBill,
    required List<CreditNoteLine> returnLines,
    required String refundMethod,
    String? reason,
  }) async {
    final validation = ReturnPolicy.validateReturn(originalBill, returnLines);
    if (!validation.isValid) {
      throw StateError(validation.errors.join(', '));
    }

    final totalRefund = ReturnPolicy.computeRefund(returnLines);
    final nextNumber = await _creditNotes.generateNextCreditNoteNumber();

    final creditNote = CreditNote(
      id: '', // Will be assigned by repository/DB
      userId: originalBill.userId ?? '',
      originalBillId: originalBill.id,
      creditNoteNumber: nextNumber,
      customerId: originalBill.customerId,
      customerName: originalBill.customerName,
      returnDate: DateTime.now(),
      totalRefundAmount: totalRefund,
      refundMethod: refundMethod,
      status: 'issued',
      lineItems: returnLines,
      reason: reason,
      createdAt: DateTime.now(),
    );

    return await _creditNotes.createCreditNote(creditNote);
  }
}
