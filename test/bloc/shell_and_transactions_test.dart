import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_state.dart';

class _StubBillsRepo implements BillsRepository {
  _StubBillsRepo(this._stream);

  final Stream<List<Bill>> _stream;

  @override
  Stream<List<Bill>> watchBillsForCurrentUser() => _stream;

  @override
  Future<String> createBill({
    required String businessName,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> productsJson,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethod,
    required String paymentStatus,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> nextBillSequenceNumber() => throw UnimplementedError();

  @override
  Future<List<Bill>> fetchPartialBillsForUser(String userId) =>
      throw UnimplementedError();

  @override
  Future<void> replaceSignedBillFromLocalFile({
    required String billId,
    required String localFilePath,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteBillById(String billId) => throw UnimplementedError();

  @override
  Future<void> updateBillPayment({
    required String billId,
    required double newPaidAmount,
    required double totalAmount,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('CompleteTransactionsBloc', () {
    late StreamController<List<Bill>> sc;

    setUp(() => sc = StreamController<List<Bill>>.broadcast());
    tearDown(() async {
      await sc.close();
    });

    blocTest<CompleteTransactionsBloc, CompleteTransactionsViewState>(
      'setSearchQuery updates state',
      build: () => CompleteTransactionsBloc(
        ObserveBillsUseCase(_StubBillsRepo(sc.stream)),
      ),
      act: (b) => b.add(const CompleteSearchQueryChanged('acme')),
      expect: () => [
        const CompleteTransactionsViewState(searchQuery: 'acme'),
      ],
    );
  });
}
