import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/dashboard/cubit/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._billsRepository, this._profileRepository)
      : super(const DashboardState()) {
    _listen();
  }

  final BillsRepository _billsRepository;
  final ProfileRepository _profileRepository;

  StreamSubscription<List<Map<String, dynamic>>>? _billsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSub;

  void _listen() {
    final profileStream = _profileRepository.watchProfileForCurrentUser();
    if (profileStream != null) {
      _profileSub = profileStream.listen(
        (rows) => emit(state.copyWith(profileRows: rows)),
      );
    }
    _billsSub = _billsRepository.watchBillsForCurrentUser().listen(
      (rows) => emit(state.copyWith(billsRows: rows)),
    );
  }

  @override
  Future<void> close() {
    _billsSub?.cancel();
    _profileSub?.cancel();
    return super.close();
  }
}
