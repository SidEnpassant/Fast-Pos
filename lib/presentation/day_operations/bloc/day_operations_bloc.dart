import 'package:bloc/bloc.dart';
import 'package:inventopos/application/automation/automation_use_cases.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/presentation/day_operations/bloc/day_operations_event.dart';
import 'package:inventopos/presentation/day_operations/bloc/day_operations_state.dart';

class DayOperationsBloc extends Bloc<DayOperationsEvent, DayOperationsState> {
  DayOperationsBloc(this._opening, this._eod, this._expenseSpike)
      : super(const DayOperationsState()) {
    on<DayOperationsStarted>(_onStarted);
    on<DayOperationsSnapshotComputed>(_onComputed);
  }

  final BuildOpeningSnapshotUseCase _opening;
  final BuildEodSummaryUseCase _eod;
  final EvaluateExpenseSpikeUseCase _expenseSpike;

  Future<void> _onStarted(
    DayOperationsStarted event,
    Emitter<DayOperationsState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final open = _opening(
      bills: event.bills,
      reorderAlertCount: event.reorderAlertCount,
    );
    final eod = _eod(event.bills);
    final spike = _expenseSpike(event.expenses.cast<Expense>());
    add(DayOperationsSnapshotComputed(
      partialCount: open.partialCount,
      pending: open.pending,
      lowStockCount: open.lowStockCount,
      billCount: eod.billCount,
      revenue: eod.revenue,
      collected: eod.collected,
      eodPending: eod.pending,
      expenseSpike: spike,
    ));
  }

  void _onComputed(
    DayOperationsSnapshotComputed event,
    Emitter<DayOperationsState> emit,
  ) {
    emit(state.copyWith(
      partialCount: event.partialCount,
      pending: event.pending,
      lowStockCount: event.lowStockCount,
      billCount: event.billCount,
      revenue: event.revenue,
      collected: event.collected,
      eodPending: event.eodPending,
      expenseSpike: event.expenseSpike,
      loading: false,
    ));
  }
}
