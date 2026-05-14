import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_state.dart';

void main() {
  group('BillDraftBloc', () {
    test('initial state is empty', () {
      final bloc = BillDraftBloc();
      addTearDown(bloc.close);
      expect(bloc.state, const BillDraftState());
    });

    blocTest<BillDraftBloc, BillDraftState>(
      'adds and removes lines',
      build: BillDraftBloc.new,
      act: (bloc) {
        bloc.add(
          const BillDraftLineAdded(
            BillDraftLine(name: 'A', price: 10, quantity: 2),
          ),
        );
        bloc.add(const BillDraftLineRemoved(0));
      },
      expect: () => [
        const BillDraftState(
          lines: [BillDraftLine(name: 'A', price: 10, quantity: 2)],
        ),
        const BillDraftState(lines: []),
      ],
    );

    blocTest<BillDraftBloc, BillDraftState>(
      'clears draft',
      build: BillDraftBloc.new,
      act: (bloc) {
        bloc.add(
          const BillDraftLineAdded(
            BillDraftLine(name: 'X', price: 1, quantity: 1),
          ),
        );
        bloc.add(const BillDraftCleared());
      },
      expect: () => [
        const BillDraftState(
          lines: [BillDraftLine(name: 'X', price: 1, quantity: 1)],
        ),
        const BillDraftState(),
      ],
    );
  });
}
