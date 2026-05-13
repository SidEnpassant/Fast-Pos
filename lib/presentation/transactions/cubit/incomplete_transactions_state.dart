import 'package:equatable/equatable.dart';

class IncompleteTransactionsViewState extends Equatable {
  const IncompleteTransactionsViewState({
    this.rawBillRows = const [],
    this.searchQuery = '',
    this.selectedDate,
    this.isSearching = false,
  });

  final List<Map<String, dynamic>> rawBillRows;
  final String searchQuery;
  final DateTime? selectedDate;
  final bool isSearching;

  IncompleteTransactionsViewState copyWith({
    List<Map<String, dynamic>>? rawBillRows,
    String? searchQuery,
    DateTime? selectedDate,
    bool? isSearching,
    bool clearSelectedDate = false,
  }) {
    return IncompleteTransactionsViewState(
      rawBillRows: rawBillRows ?? this.rawBillRows,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props =>
      [rawBillRows, searchQuery, selectedDate, isSearching];
}
