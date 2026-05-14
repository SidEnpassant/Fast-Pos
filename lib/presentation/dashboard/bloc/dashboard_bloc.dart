import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_event.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._observeBills, this._profileRepository)
      : super(const DashboardState()) {
    on<DashboardBillsReceived>(_onBillsReceived);
    on<DashboardProfileReceived>(_onProfileReceived);

    _billsSub = _observeBills().listen(
      (bills) => add(DashboardBillsReceived(bills)),
    );
    final profileStream = _profileRepository.watchProfileForCurrentUser();
    if (profileStream != null) {
      _profileSub = profileStream.listen(
        (profiles) => add(DashboardProfileReceived(profiles)),
      );
    }
  }

  final ObserveBillsUseCase _observeBills;
  final ProfileRepository _profileRepository;

  StreamSubscription<dynamic>? _billsSub;
  StreamSubscription<dynamic>? _profileSub;

  void _onBillsReceived(
    DashboardBillsReceived event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(bills: event.bills));
  }

  void _onProfileReceived(
    DashboardProfileReceived event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(profiles: event.profiles));
  }

  @override
  Future<void> close() {
    _billsSub?.cancel();
    _profileSub?.cancel();
    return super.close();
  }
}
