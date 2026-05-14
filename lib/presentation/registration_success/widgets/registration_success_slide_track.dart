import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_bloc.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_event.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_state.dart';

/// Slide-to-confirm control; forwards gestures to [RegistrationSuccessBloc].
class RegistrationSuccessSlideTrack extends StatelessWidget {
  const RegistrationSuccessSlideTrack({super.key});

  static const double _buttonHeight = 70;
  static const double _thumbSize = 60;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationSuccessBloc, RegistrationSuccessState>(
      builder: (context, state) {
        final horizontalPadding = 32.0;
        final containerWidth =
            MediaQuery.sizeOf(context).width - horizontalPadding * 2;
        final maxSlide = containerWidth - _thumbSize;

        return Container(
          height: _buttonHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _buttonHeight,
                width: state.sliderPosition * containerWidth + _thumbSize,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C851), Color(0xFF007E33)],
                  ),
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              if (state.sliderPosition < 0.8)
                const Center(
                  child: Text(
                    'Slide to get started  →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (state.sliderPosition >= 0.8)
                const Center(
                  child: Text(
                    "Let's Go! 🚀",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Positioned(
                left: state.sliderPosition * maxSlide,
                top: (_buttonHeight - _thumbSize) / 2,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final newPosition =
                        (details.localPosition.dx / maxSlide).clamp(0.0, 1.0);
                    context.read<RegistrationSuccessBloc>().add(
                          RegistrationSuccessSliderChanged(newPosition),
                        );
                  },
                  onPanEnd: (_) {
                    context.read<RegistrationSuccessBloc>().add(
                          const RegistrationSuccessSliderReleased(),
                        );
                  },
                  child: AnimatedContainer(
                    duration: Duration(
                      milliseconds: state.sliderPosition > 0.1 ? 0 : 300,
                    ),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      state.sliderPosition >= 0.95
                          ? Icons.check_rounded
                          : Icons.arrow_forward_ios_rounded,
                      color: state.sliderPosition >= 0.95
                          ? const Color(0xFF00C851)
                          : const Color(0xFF4facfe),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
