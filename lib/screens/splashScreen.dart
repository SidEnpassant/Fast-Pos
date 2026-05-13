import 'package:flutter/material.dart';
import 'package:inventopos/screens/login/loginScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Legacy splash using Supabase stream directly.
/// Prefer the app entry in [main.dart] with go_router.

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                Supabase.instance.client.auth.currentSession == null) {
              return const CircularProgressIndicator();
            }
            final session = snapshot.data?.session ??
                Supabase.instance.client.auth.currentSession;
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
