import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';

import 'tax_settings_event.dart';
import 'tax_settings_state.dart';

class TaxSettingsBloc extends Bloc<TaxSettingsEvent, TaxSettingsState> {
  TaxSettingsBloc({
    required ObserveProfileForCurrentUserUseCase observeProfile,
    required ProfileRepository profileRepository,
    required AuthRepository authRepository,
  })  : _observeProfile = observeProfile,
        _profileRepository = profileRepository,
        _authRepository = authRepository,
        super(const TaxSettingsState()) {
    on<TaxSettingsStarted>(_onStarted);
    on<TaxSettingsGstinUpdated>(_onGstinUpdated);
    on<TaxSettingsStateCodeUpdated>(_onStateCodeUpdated);
    on<TaxSettingsCompositionToggled>(_onCompositionToggled);
    on<TaxSettingsSaved>(_onSaved);
  }

  final ObserveProfileForCurrentUserUseCase _observeProfile;
  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;

  Future<void> _onStarted(
    TaxSettingsStarted event,
    Emitter<TaxSettingsState> emit,
  ) async {
    emit(state.copyWith(status: TaxSettingsStatus.loading));
    try {
      final stream = _observeProfile();
      if (stream == null) {
        emit(state.copyWith(status: TaxSettingsStatus.initial));
        return;
      }
      final profiles = await stream.first;
      final profile = profiles.firstOrNull;
      if (profile != null) {
        emit(
          state.copyWith(
            status: TaxSettingsStatus.initial,
            gstin: profile.gstNumber ?? '',
            stateCode: profile.stateCode ?? '',
            isComposition: profile.isCompositionDealer,
          ),
        );
      } else {
        emit(state.copyWith(status: TaxSettingsStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        status: TaxSettingsStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void _onGstinUpdated(
    TaxSettingsGstinUpdated event,
    Emitter<TaxSettingsState> emit,
  ) {
    emit(state.copyWith(gstin: event.gstin, status: TaxSettingsStatus.initial));
  }

  void _onStateCodeUpdated(
    TaxSettingsStateCodeUpdated event,
    Emitter<TaxSettingsState> emit,
  ) {
    emit(state.copyWith(
        stateCode: event.stateCode, status: TaxSettingsStatus.initial));
  }

  void _onCompositionToggled(
    TaxSettingsCompositionToggled event,
    Emitter<TaxSettingsState> emit,
  ) {
    emit(state.copyWith(
        isComposition: event.isComposition, status: TaxSettingsStatus.initial));
  }

  Future<void> _onSaved(
    TaxSettingsSaved event,
    Emitter<TaxSettingsState> emit,
  ) async {
    emit(state.copyWith(status: TaxSettingsStatus.loading));
    try {
      final uid = _authRepository.currentSession?.userId;
      if (uid != null) {
        await _profileRepository.updateProfileFields(
          userId: uid,
          columns: {
            'gst_number': state.gstin,
            'state_code': state.stateCode,
            'is_composition': state.isComposition,
          },
        );
      }
      emit(state.copyWith(status: TaxSettingsStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: TaxSettingsStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
