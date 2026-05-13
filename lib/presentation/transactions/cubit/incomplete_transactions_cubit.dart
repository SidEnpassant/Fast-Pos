import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/presentation/transactions/cubit/incomplete_transactions_state.dart';

class IncompleteTransactionsCubit
    extends Cubit<IncompleteTransactionsViewState> {
  IncompleteTransactionsCubit(this._billsRepository)
      : super(const IncompleteTransactionsViewState()) {
    _sub = _billsRepository.watchBillsForCurrentUser().listen(
          (rows) => emit(state.copyWith(rawBillRows: rows)),
        );
  }

  final BillsRepository _billsRepository;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  void setSearchQuery(String q) =>
      emit(state.copyWith(searchQuery: q.toLowerCase()));

  void setSelectedDate(DateTime? d) =>
      emit(state.copyWith(selectedDate: d, clearSelectedDate: d == null));

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
