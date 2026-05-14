import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

class IncompleteTransactionsViewState extends Equatable {
  const IncompleteTransactionsViewState({
    this.bills = const [],
    this.searchQuery = '',
    this.selectedDate,
    this.isSearching = false,
  });

  final List<Bill> bills;
  final String searchQuery;
  final DateTime? selectedDate;
  final bool isSearching;

  IncompleteTransactionsViewState copyWith({
    List<Bill>? bills,
    String? searchQuery,
    DateTime? selectedDate,
    bool? isSearching,
    bool clearSelectedDate = false,
  }) {
    return IncompleteTransactionsViewState(
      bills: bills ?? this.bills,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props =>
      [bills, searchQuery, selectedDate, isSearching];
}
