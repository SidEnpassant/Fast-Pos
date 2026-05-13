import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/presentation/transactions/cubit/complete_transactions_state.dart';

class CompleteTransactionsCubit extends Cubit<CompleteTransactionsViewState> {
  CompleteTransactionsCubit(this._billsRepository)
      : super(const CompleteTransactionsViewState()) {
    _sub = _billsRepository.watchBillsForCurrentUser().listen(
          (rows) => emit(state.copyWith(rawBillRows: rows)),
        );
  }

  final BillsRepository _billsRepository;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  void setSearchQuery(String q) => emit(state.copyWith(searchQuery: q));

  void setDateRange(DateTime? start, DateTime? end) {
    emit(state.copyWith(startDate: start, endDate: end));
  }

  void toggleSearchMode() {
    final next = !state.isSearching;
    if (!next) {
      emit(state.copyWith(isSearching: false, searchQuery: ''));
    } else {
      emit(state.copyWith(isSearching: true));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
