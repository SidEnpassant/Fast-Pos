import 'package:inventopos/domain/entities/cash_entry.dart';
import 'package:inventopos/domain/repositories/cash_register_repository.dart';

class RecordCashEntryUseCase {
  RecordCashEntryUseCase(this._repository);

  final CashRegisterRepository _repository;

  Future<CashEntry> call({
    required String userId,
    required double amount,
    required String type, // 'in' or 'out'
    String? referenceId,
    String? referenceType,
    String? note,
  }) async {
    final entry = CashEntry(
      id: '', // Repo will generate UUID
      userId: userId,
      entryDate: DateTime.now(),
      type: type,
      amount: amount,
      referenceId: referenceId,
      referenceType: referenceType,
      note: note,
      createdAt: DateTime.now(),
    );

    return _repository.createEntry(entry);
  }
}
