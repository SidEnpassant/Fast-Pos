import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/repositories/loyalty_repository.dart';
import 'loyalty_event.dart';
import 'loyalty_state.dart';

class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  LoyaltyBloc({required LoyaltyRepository repository})
      : _repository = repository,
        super(const LoyaltyState()) {
    on<LoadLoyaltyConfig>(_onLoadLoyaltyConfig);
    on<SaveLoyaltyConfig>(_onSaveLoyaltyConfig);
  }

  final LoyaltyRepository _repository;

  Future<void> _onLoadLoyaltyConfig(
    LoadLoyaltyConfig event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(state.copyWith(status: LoyaltyStatus.loading));
    try {
      final config = await _repository.getLoyaltyConfig(event.userId);
      emit(state.copyWith(status: LoyaltyStatus.success, config: config));
    } catch (e) {
      emit(state.copyWith(status: LoyaltyStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onSaveLoyaltyConfig(
    SaveLoyaltyConfig event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(state.copyWith(status: LoyaltyStatus.loading));
    try {
      await _repository.saveLoyaltyConfig(event.userId, event.config);
      emit(state.copyWith(status: LoyaltyStatus.success, config: event.config));
    } catch (e) {
      emit(state.copyWith(status: LoyaltyStatus.failure, error: e.toString()));
    }
  }
}
