import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/auth_login/view/login_screen.dart';

/// Splash gate driven by [AuthRepository.sessionStream] (no Supabase in the widget).
///
/// Provide [AuthRepository] above this widget (same tree as [fastPosRoot]).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    return Scaffold(
      body: Center(
        child: StreamBuilder(
          stream: auth.sessionStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                auth.currentSession == null) {
              return const CircularProgressIndicator();
            }
            final session = snapshot.data ?? auth.currentSession;
            if (session != null) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'You are signed in. Use the main app entry (go_router).',
                  ),
                ),
              );
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
