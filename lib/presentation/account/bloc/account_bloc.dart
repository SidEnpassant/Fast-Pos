import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/application/profile/patch_account_profile_field_use_case.dart';
import 'package:inventopos/application/profile/replace_account_signature_use_case.dart';
import 'package:inventopos/data/mappers/user_profile_mapper.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/account/bloc/account_event.dart';
import 'package:inventopos/presentation/account/bloc/account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(
    this._observeProfile,
    this._patchField,
    this._replaceSignature,
    this._profiles,
    this._auth,
  ) : super(const AccountState()) {
    on<AccountProfilesReceived>(_onProfilesReceived);
    on<AccountFieldPatched>(_onFieldPatched);
    on<AccountPatchFieldRequested>(_onPatchFieldRequested);
    on<AccountReplaceSignatureRequested>(_onReplaceSignatureRequested);
    on<AccountUiFeedbackConsumed>(_onFeedbackConsumed);
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
  final PatchAccountProfileFieldUseCase _patchField;
  final ReplaceAccountSignatureUseCase _replaceSignature;
  final ProfileRepository _profiles;
  final AuthRepository _auth;
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

  Future<void> _onPatchFieldRequested(
    AccountPatchFieldRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(mutationBusy: true));
    final uid = _auth.currentSession?.userId;
    if (uid == null) {
      emit(
        state.copyWith(
          mutationBusy: false,
          feedbackMessage: 'Not signed in',
          feedbackIsError: true,
        ),
      );
      return;
    }
    try {
      await _patchField(
        userId: uid,
        fieldKey: event.fieldKey,
        value: event.value,
      );
      final next = Map<String, dynamic>.from(state.fields);
      next[event.fieldKey] = event.value;
      emit(
        state.copyWith(
          fields: next,
          mutationBusy: false,
          feedbackMessage: 'Updated successfully',
          feedbackIsError: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          mutationBusy: false,
          feedbackMessage: 'Update failed',
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onReplaceSignatureRequested(
    AccountReplaceSignatureRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(mutationBusy: true));
    final uid = _auth.currentSession?.userId;
    if (uid == null) {
      emit(
        state.copyWith(
          mutationBusy: false,
          feedbackMessage: 'Not signed in',
          feedbackIsError: true,
        ),
      );
      return;
    }
    try {
      await _replaceSignature(
        userId: uid,
        localFilePath: event.localFilePath,
      );
      final profile = await _profiles.fetchCurrentUserProfileSnapshot();
      final next = Map<String, dynamic>.from(state.fields);
      if (profile?.signatureUrl != null) {
        next['signatureUrl'] = profile!.signatureUrl!;
      }
      emit(
        state.copyWith(
          fields: next,
          mutationBusy: false,
          feedbackMessage: 'Profile picture updated successfully',
          feedbackIsError: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          mutationBusy: false,
          feedbackMessage: 'Failed to update profile picture',
          feedbackIsError: true,
        ),
      );
    }
  }

  void _onFeedbackConsumed(
    AccountUiFeedbackConsumed event,
    Emitter<AccountState> emit,
  ) {
    emit(state.copyWith(clearFeedback: true));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
