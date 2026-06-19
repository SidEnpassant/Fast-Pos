part of 'daybook_bloc.dart';

abstract class DayBookEvent {}

class DayBookStarted extends DayBookEvent {
  DayBookStarted({this.date});
  final DateTime? date;
}

class DayBookDateChanged extends DayBookEvent {
  DayBookDateChanged(this.date);
  final DateTime date;
}

class DayBookEntryAdded extends DayBookEvent {
  DayBookEntryAdded({
    required this.amount,
    required this.type,
    this.note,
  });
  final double amount;
  final String type;
  final String? note;
}
