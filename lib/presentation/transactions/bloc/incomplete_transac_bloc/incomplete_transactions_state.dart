import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

class IncompleteTransactionsViewState extends Equatable {
  const IncompleteTransactionsViewState({
    this.bills = const [],
    this.searchQuery = '',
    this.selectedDate,
    this.isSearching = false,
    this.groupedTransactions = const {},
    this.loading = true,
  });

  final List<Bill> bills;
  final String searchQuery;
  final DateTime? selectedDate;
  final bool isSearching;
  final Map<String, List<Bill>> groupedTransactions;
  final bool loading;

  bool get hasPartialBills => groupedTransactions.isNotEmpty;

  IncompleteTransactionsViewState copyWith({
    List<Bill>? bills,
    String? searchQuery,
    DateTime? selectedDate,
    bool? isSearching,
    Map<String, List<Bill>>? groupedTransactions,
    bool? loading,
    bool clearSelectedDate = false,
  }) {
    return IncompleteTransactionsViewState(
      bills: bills ?? this.bills,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      isSearching: isSearching ?? this.isSearching,
      groupedTransactions: groupedTransactions ?? this.groupedTransactions,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        selectedDate,
        isSearching,
        groupedTransactions,
        loading,
      ];
}
