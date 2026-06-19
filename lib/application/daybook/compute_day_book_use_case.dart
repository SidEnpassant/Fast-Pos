import 'package:inventopos/domain/entities/cash_entry.dart';
import 'package:inventopos/domain/repositories/cash_register_repository.dart';

class DayBookSummary {
  DayBookSummary({
    required this.entries,
    required this.totalIn,
    required this.totalOut,
    required this.netBalance,
  });

  final List<CashEntry> entries;
  final double totalIn;
  final double totalOut;
  final double netBalance;
}

class ComputeDayBookUseCase {
  ComputeDayBookUseCase(this._repository);

  final CashRegisterRepository _repository;

  Stream<DayBookSummary> call(String userId, DateTime date) {
    return _repository.watchEntriesForDate(userId, date).map((entries) {
      double totalIn = 0;
      double totalOut = 0;

      for (final entry in entries) {
        if (entry.type == 'in') {
          totalIn += entry.amount;
        } else {
          totalOut += entry.amount;
        }
      }

      return DayBookSummary(
        entries: entries,
        totalIn: totalIn,
        totalOut: totalOut,
        netBalance: totalIn - totalOut,
      );
    });
  }
}
