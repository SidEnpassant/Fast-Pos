import '../entities/cash_entry.dart';

class DayBookSummary {
  final DateTime date;
  final double openingBalance;
  final double cashIn;
  final double cashOut;
  final double closingBalance;
  final List<CashEntry> entries;

  const DayBookSummary({
    required this.date,
    required this.openingBalance,
    required this.cashIn,
    required this.cashOut,
    required this.closingBalance,
    required this.entries,
  });
}

class DayBookCalculator {
  static DayBookSummary computeDayBook(List<CashEntry> entries, double openingBalance, DateTime date) {
    double cashIn = 0;
    double cashOut = 0;

    for (final entry in entries) {
      if (entry.type == 'sale_cash' || entry.type == 'payment_received' || entry.type == 'adjustment_in') {
        cashIn += entry.amount;
      } else {
        cashOut += entry.amount;
      }
    }

    return DayBookSummary(
      date: date,
      openingBalance: openingBalance,
      cashIn: cashIn,
      cashOut: cashOut,
      closingBalance: openingBalance + cashIn - cashOut,
      entries: entries,
    );
  }

  static List<Map<String, dynamic>> computeRunningBalance(List<CashEntry> entries, double openingBalance) {
    final sortedEntries = List<CashEntry>.from(entries)
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

    double currentBalance = openingBalance;
    final List<Map<String, dynamic>> result = [];

    for (final entry in sortedEntries) {
      if (entry.type == 'sale_cash' || entry.type == 'payment_received' || entry.type == 'adjustment_in') {
        currentBalance += entry.amount;
      } else {
        currentBalance -= entry.amount;
      }
      result.add({
        'entry': entry,
        'runningBalance': currentBalance,
      });
    }

    return result;
  }
}