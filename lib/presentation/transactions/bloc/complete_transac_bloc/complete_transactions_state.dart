import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

class CompleteTransactionsViewState extends Equatable {
  const CompleteTransactionsViewState({
    this.bills = const [],
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.isSearching = false,
  });

  final List<Bill> bills;
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isSearching;

  CompleteTransactionsViewState copyWith({
    List<Bill>? bills,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool? isSearching,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return CompleteTransactionsViewState(
      bills: bills ?? this.bills,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props =>
      [bills, searchQuery, startDate, endDate, isSearching];
}
