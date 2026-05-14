import 'package:bloc/bloc.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_event.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_state.dart';

class RegistrationSuccessBloc
    extends Bloc<RegistrationSuccessEvent, RegistrationSuccessState> {
  RegistrationSuccessBloc() : super(const RegistrationSuccessState()) {
    on<RegistrationSuccessSliderChanged>(_onSliderChanged);
    on<RegistrationSuccessSliderReleased>(_onSliderReleased);
  }

  Future<void> _onSliderChanged(
    RegistrationSuccessSliderChanged event,
    Emitter<RegistrationSuccessState> emit,
  ) async {
    final value = event.normalizedPosition.clamp(0.0, 1.0);
    if (value >= 0.95 && !state.hasTriggeredGo) {
      var next = state.copyWith(sliderPosition: value, hasTriggeredGo: true);
      emit(next);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      next = next.copyWith(shouldNavigateToDashboard: true);
      emit(next);
      return;
    }
    emit(state.copyWith(sliderPosition: value));
  }

  void _onSliderReleased(
    RegistrationSuccessSliderReleased event,
    Emitter<RegistrationSuccessState> emit,
  ) {
    if (state.sliderPosition < 0.95) {
      emit(state.copyWith(sliderPosition: 0));
    }
  }
}
