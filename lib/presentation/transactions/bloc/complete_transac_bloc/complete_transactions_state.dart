import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

class CompleteTransactionsViewState extends Equatable {
  const CompleteTransactionsViewState({
    this.bills = const [],
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.isSearching = false,
    this.groupedTransactions = const {},
    this.loading = true,
  });

  final List<Bill> bills;
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isSearching;
  final Map<String, List<Bill>> groupedTransactions;
  final bool loading;

  CompleteTransactionsViewState copyWith({
    List<Bill>? bills,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool? isSearching,
    bool clearStartDate = false,
    bool clearEndDate = false,
    Map<String, List<Bill>>? groupedTransactions,
    bool? loading,
  }) {
    return CompleteTransactionsViewState(
      bills: bills ?? this.bills,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isSearching: isSearching ?? this.isSearching,
      groupedTransactions: groupedTransactions ?? this.groupedTransactions,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [
        bills,
        searchQuery,
        startDate,
        endDate,
        isSearching,
        groupedTransactions,
        loading,
      ];
}
