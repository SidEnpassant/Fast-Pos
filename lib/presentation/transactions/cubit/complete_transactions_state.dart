import 'package:equatable/equatable.dart';

class CompleteTransactionsViewState extends Equatable {
  const CompleteTransactionsViewState({
    this.rawBillRows = const [],
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.isSearching = false,
  });

  final List<Map<String, dynamic>> rawBillRows;
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isSearching;

  CompleteTransactionsViewState copyWith({
    List<Map<String, dynamic>>? rawBillRows,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool? isSearching,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return CompleteTransactionsViewState(
      rawBillRows: rawBillRows ?? this.rawBillRows,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props =>
      [rawBillRows, searchQuery, startDate, endDate, isSearching];
}
