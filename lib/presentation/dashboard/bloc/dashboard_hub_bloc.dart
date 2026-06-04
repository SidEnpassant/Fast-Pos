import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_event.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';

class DashboardHubBloc extends Bloc<DashboardHubEvent, DashboardHubState> {
  DashboardHubBloc(
    this._observeBills,
    this._profileRepository,
    this._products,
    this._expenses,
    this._customers,
    this._sync,
    this._notifications,
  ) : super(const DashboardHubState()) {
    on<DashboardHubStarted>(_onStarted);
    on<DashboardHubBillsReceived>(_onBills);
    on<DashboardHubProfileReceived>(_onProfile);
    on<DashboardHubProductsReceived>(_onProducts);
    on<DashboardHubExpensesReceived>(_onExpenses);
    on<DashboardHubCustomersReceived>(_onCustomers);
    on<DashboardHubPendingSyncChanged>(_onPending);
    on<DashboardHubNotificationsReceived>(_onNotifications);
    on<DashboardHubConnectivityChanged>(_onConnectivity);
    on<DashboardHubAiUnreadChanged>(_onAiUnread);
  }

  final ObserveBillsUseCase _observeBills;
  final ProfileRepository _profileRepository;
  final ProductRepository _products;
  final ExpenseRepository _expenses;
  final CustomerRepository _customers;
  final SyncRepository _sync;
  final NotificationsRepository _notifications;

  final List<StreamSubscription<dynamic>> _subs = [];

  Future<void> _onStarted(
    DashboardHubStarted event,
    Emitter<DashboardHubState> emit,
  ) async {
    await _cancelSubs();
    emit(state.copyWith(loading: true));

    _subs.add(
      _observeBills().listen((b) => add(DashboardHubBillsReceived(b))),
    );

    final profileStream = _profileRepository.watchProfileForCurrentUser();
    if (profileStream != null) {
      _subs.add(
        profileStream.listen((p) => add(DashboardHubProfileReceived(p))),
      );
    }

    _subs.add(
      _products.watchProductsForUser(event.userId).listen(
            (p) => add(DashboardHubProductsReceived(p)),
          ),
    );
    _subs.add(
      _expenses.watchExpensesForUser(event.userId).listen(
            (e) => add(DashboardHubExpensesReceived(e)),
          ),
    );
    _subs.add(
      _customers.watchCustomersForUser(event.userId).listen(
            (c) => add(DashboardHubCustomersReceived(c)),
          ),
    );
    _subs.add(
      _sync.watchPendingOutboxCount(event.userId).listen(
            (n) => add(DashboardHubPendingSyncChanged(n)),
          ),
    );
    _subs.add(
      _notifications.watchNotifications(event.userId).listen(
            (n) => add(DashboardHubNotificationsReceived(n)),
          ),
    );

    final online = await _sync.isOnline();
    add(DashboardHubConnectivityChanged(isOnline: online));
  }

  void _onBills(DashboardHubBillsReceived e, Emitter<DashboardHubState> emit) {
    emit(state.copyWith(bills: e.bills, loading: false));
  }

  void _onProfile(
    DashboardHubProfileReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(profiles: e.profiles));
  }

  void _onProducts(
    DashboardHubProductsReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(products: e.products, loading: false));
  }

  void _onExpenses(
    DashboardHubExpensesReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(expenses: e.expenses));
  }

  void _onCustomers(
    DashboardHubCustomersReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(customers: e.customers));
  }

  void _onPending(
    DashboardHubPendingSyncChanged e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(pendingSyncCount: e.count));
  }

  void _onNotifications(
    DashboardHubNotificationsReceived e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(notificationCount: e.notifications.length));
  }

  void _onConnectivity(
    DashboardHubConnectivityChanged e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(isOnline: e.isOnline));
  }

  void _onAiUnread(
    DashboardHubAiUnreadChanged e,
    Emitter<DashboardHubState> emit,
  ) {
    emit(state.copyWith(aiUnreadCount: e.count));
  }

  Future<void> _cancelSubs() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  @override
  Future<void> close() async {
    await _cancelSubs();
    return super.close();
  }
}
