import 'package:flutter/material.dart';
import 'package:inventopos/screens/bottom%20navigation%20bar/bottomNavbar.dart';
import 'package:inventopos/screens/login/loginScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
              return NavBarScreen();
            }
            return LoginScreen();
          },
        ),
      ),
    );
  }
}
