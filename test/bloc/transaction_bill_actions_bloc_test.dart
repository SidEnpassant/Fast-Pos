import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/billing/delete_bill_use_case.dart';
import 'package:inventopos/application/billing/replace_signed_bill_use_case.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_state.dart';

class _SpyBillsRepo implements BillsRepository {
  _SpyBillsRepo(this._stream);

  final Stream<List<Bill>> _stream;

  Object? replaceError;
  Object? deleteError;
  String? lastReplaceBillId;
  String? lastDeleteBillId;

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
  String? clientId,
  String? customerId,
  List<Map<String, dynamic>>? discountBreakdown,
  String? contentHash,
  double taxAmount = 0.0,
  String invoiceType = 'tax_invoice',
}) async {
    throw UnimplementedError();
  }

  @override
  Future<String> nextBillSequenceNumber() => throw UnimplementedError();

  @override
  Future<List<Bill>> fetchPartialBillsForUser(String userId) =>
      throw UnimplementedError();

  @override
  Future<void> replaceSignedBillFromLocalFile({
    required String billId,
    required String localFilePath,
  }) async {
    if (replaceError != null) throw replaceError!;
    lastReplaceBillId = billId;
  }

  @override
  Future<void> deleteBillById(String billId) async {
    if (deleteError != null) throw deleteError!;
    lastDeleteBillId = billId;
  }

  @override
  Future<void> updateBillPayment({
    required String billId,
    required double newPaidAmount,
    required double totalAmount,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updatePdfUrl({
    required String billId,
    required String pdfUrl,
    required DateTime pdfUpdatedAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> patchLocalBillMetadata(
    String billId,
    Map<String, dynamic> fields,
  ) async {}

  @override
  Future<Bill?> fetchLocalBillById(String billId) async => null;

  @override
  Future<Bill?> fetchBillById(String billId) => throw UnimplementedError();

  @override
  Stream<List<Bill>> watchBillsForCustomer({
    required String userId,
    String? customerId,
    String? customerPhone,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('TransactionBillActionsBloc', () {
    late StreamController<List<Bill>> sc;
    late _SpyBillsRepo repo;

    setUp(() {
      sc = StreamController<List<Bill>>.broadcast();
      repo = _SpyBillsRepo(sc.stream);
    });

    tearDown(() async {
      await sc.close();
    });

    blocTest<TransactionBillActionsBloc, TransactionBillActionsState>(
      'replace signed emits success',
      build: () => TransactionBillActionsBloc(
        replaceSignedBill: ReplaceSignedBillUseCase(repo),
        deleteBill: DeleteBillUseCase(repo),
      ),
      act: (b) => b.add(
        const TransactionBillReplaceSignedRequested(
          billId: 'b1',
          localFilePath: '/tmp/x.jpg',
        ),
      ),
      expect: () => [
        const TransactionBillActionsState(
          phase: TransactionBillActionsPhase.busy,
        ),
        const TransactionBillActionsState(
          phase: TransactionBillActionsPhase.success,
          message: 'Signed bill updated successfully',
        ),
      ],
      verify: (_) {
        expect(repo.lastReplaceBillId, 'b1');
      },
    );

    blocTest<TransactionBillActionsBloc, TransactionBillActionsState>(
      'replace signed emits failure on error',
      build: () {
        repo.replaceError = Exception('network');
        return TransactionBillActionsBloc(
          replaceSignedBill: ReplaceSignedBillUseCase(repo),
          deleteBill: DeleteBillUseCase(repo),
        );
      },
      act: (b) => b.add(
        const TransactionBillReplaceSignedRequested(
          billId: 'b1',
          localFilePath: '/tmp/x.jpg',
        ),
      ),
      expect: () => [
        const TransactionBillActionsState(
          phase: TransactionBillActionsPhase.busy,
        ),
        isA<TransactionBillActionsState>().having(
          (s) => s.phase,
          'phase',
          TransactionBillActionsPhase.failure,
        ),
      ],
    );

    blocTest<TransactionBillActionsBloc, TransactionBillActionsState>(
      'delete emits success',
      build: () => TransactionBillActionsBloc(
        replaceSignedBill: ReplaceSignedBillUseCase(repo),
        deleteBill: DeleteBillUseCase(repo),
      ),
      act: (b) => b.add(const TransactionBillDeleteRequested('b2')),
      expect: () => [
        const TransactionBillActionsState(
          phase: TransactionBillActionsPhase.busy,
        ),
        const TransactionBillActionsState(
          phase: TransactionBillActionsPhase.success,
          message: 'Transaction and associated bill deleted successfully',
        ),
      ],
      verify: (_) {
        expect(repo.lastDeleteBillId, 'b2');
      },
    );
  });
}
