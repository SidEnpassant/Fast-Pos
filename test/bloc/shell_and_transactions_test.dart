import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/presentation/transactions/cubit/complete_transactions_cubit.dart';
import 'package:inventopos/presentation/transactions/cubit/complete_transactions_state.dart';

class _StubBillsRepo implements BillsRepository {
  _StubBillsRepo(this._stream);

  final Stream<List<Map<String, dynamic>>> _stream;

  @override
  Stream<List<Map<String, dynamic>>> watchBillsForCurrentUser() => _stream;
}

void main() {
  group('CompleteTransactionsCubit', () {
    late StreamController<List<Map<String, dynamic>>> sc;

    setUp(() => sc = StreamController<List<Map<String, dynamic>>>.broadcast());
    tearDown(() async {
      await sc.close();
    });

    blocTest<CompleteTransactionsCubit, CompleteTransactionsViewState>(
      'setSearchQuery updates state',
      build: () => CompleteTransactionsCubit(_StubBillsRepo(sc.stream)),
      act: (c) => c.setSearchQuery('acme'),
      expect: () => [
        const CompleteTransactionsViewState(searchQuery: 'acme'),
      ],
    );
  });
}
