import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/data/mappers/user_profile_mapper.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/presentation/account/bloc/account_event.dart';
import 'package:inventopos/presentation/account/bloc/account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(this._observeProfile)
      : super(const AccountState()) {
    on<AccountProfilesReceived>(_onProfilesReceived);
    on<AccountFieldPatched>(_onFieldPatched);
    on<AccountNoSession>(_onNoSession);

    final stream = _observeProfile();
    if (stream != null) {
      _subscription = stream.listen(
        (profiles) => add(AccountProfilesReceived(profiles)),
      );
    } else {
      add(const AccountNoSession());
    }
  }

  final ObserveProfileForCurrentUserUseCase _observeProfile;
  StreamSubscription<List<UserProfile>>? _subscription;

  void _onNoSession(AccountNoSession event, Emitter<AccountState> emit) {
    emit(const AccountState(fields: {}, loading: false));
  }

  void _onProfilesReceived(
    AccountProfilesReceived event,
    Emitter<AccountState> emit,
  ) {
    if (event.profiles.isEmpty) {
      emit(const AccountState(fields: {}, loading: false));
      return;
    }
    emit(
      AccountState(
        fields: UserProfileMapper.toFieldMap(event.profiles.first),
        loading: false,
      ),
    );
  }

  void _onFieldPatched(
    AccountFieldPatched event,
    Emitter<AccountState> emit,
  ) {
    final next = Map<String, dynamic>.from(state.fields);
    next[event.field] = event.value;
    emit(state.copyWith(fields: next));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
