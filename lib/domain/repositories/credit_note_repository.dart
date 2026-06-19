import '../entities/credit_note.dart';

abstract class CreditNoteRepository {
  Future<CreditNote> createCreditNote(CreditNote creditNote);
  Stream<List<CreditNote>> watchCreditNotesForUser(String userId);
  Future<CreditNote?> getCreditNoteById(String id);
  Future<List<CreditNote>> getCreditNotesForBill(String billId);
  Future<List<CreditNote>> getCreditNotesForCustomer(String customerId);
  Future<String> generateNextCreditNoteNumber();
}
