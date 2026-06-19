part of 'daybook_bloc.dart';

enum DayBookStatus { initial, loading, success, failure }

class DayBookState {
  DayBookState({
    this.status = DayBookStatus.initial,
    this.summary,
    this.selectedDate,
    this.errorMessage,
  });

  final DayBookStatus status;
  final DayBookSummary? summary;
  final DateTime? selectedDate;
  final String? errorMessage;

  DayBookState copyWith({
    DayBookStatus? status,
    DayBookSummary? summary,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return DayBookState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
