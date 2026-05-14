import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_bloc.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_state.dart';
import 'package:inventopos/presentation/registration_success/widgets/registration_success_hero.dart';
import 'package:inventopos/presentation/registration_success/widgets/registration_success_slide_track.dart';

/// Post-registration welcome + slide to open the app shell.
class RegistrationSuccessScreen extends StatefulWidget {
  const RegistrationSuccessScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1, curve: Curves.elasticOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationSuccessBloc, RegistrationSuccessState>(
      listenWhen: (p, c) =>
          !p.shouldNavigateToDashboard && c.shouldNavigateToDashboard,
      listener: (context, state) {
        context.go('/app/dashboard');
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 0, 83, 155),
                Color.fromARGB(255, 0, 113, 119),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          RegistrationSuccessHero(email: widget.email),
                          const Spacer(),
                          const RegistrationSuccessSlideTrack(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
