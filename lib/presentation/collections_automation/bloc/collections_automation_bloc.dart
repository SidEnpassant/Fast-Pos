import 'package:bloc/bloc.dart';
import 'package:inventopos/application/automation/automation_use_cases.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/presentation/collections_automation/bloc/collections_automation_event.dart';
import 'package:inventopos/presentation/collections_automation/bloc/collections_automation_state.dart';

class CollectionsAutomationBloc
    extends Bloc<CollectionsAutomationEvent, CollectionsAutomationState> {
  CollectionsAutomationBloc(this._credit)
      : super(const CollectionsAutomationState()) {
    on<CollectionsAutomationStarted>(_onStarted);
    on<CollectionsAutomationLoaded>(_onLoaded);
  }

  final EvaluateCreditExposureUseCase _credit;

  Future<void> _onStarted(
    CollectionsAutomationStarted event,
    Emitter<CollectionsAutomationState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final overdue = event.bills.where((b) {
      if (b.paidAmount >= b.totalAmount) return false;
      return b.createdAt.isBefore(
        DateTime.now().subtract(const Duration(days: 5)),
      );
    }).toList();
    final alerts = _credit(
      bills: event.bills,
      customers: event.customers.cast<Customer>(),
    );
    add(CollectionsAutomationLoaded(
      overdueBills: overdue,
      creditAlerts: alerts,
    ));
  }

  void _onLoaded(
    CollectionsAutomationLoaded event,
    Emitter<CollectionsAutomationState> emit,
  ) {
    emit(state.copyWith(
      overdueBills: event.overdueBills,
      creditAlerts: event.creditAlerts,
      loading: false,
    ));
  }
}
