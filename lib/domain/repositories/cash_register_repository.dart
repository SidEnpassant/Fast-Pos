import 'package:inventopos/domain/entities/cash_entry.dart';

abstract class CashRegisterRepository {
  Stream<List<CashEntry>> watchEntriesForDate(String userId, DateTime date);
  Stream<List<CashEntry>> watchEntriesForRange(String userId, DateTime start, DateTime end);
  Future<CashEntry> createEntry(CashEntry entry);
  Future<void> deleteEntry(String id);
}