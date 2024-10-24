import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventopos/bottom%20navigation%20bar/bottomNavbar.dart';
import 'package:inventopos/screens/Bill/BillGenerationScreen.dart';
import 'package:inventopos/screens/DashboardScreen.dart';
import 'package:inventopos/screens/Authentication/loginScreen.dart';
import 'package:inventopos/screens/Authentication/signUpScreen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasData) {
              // User is signed in, navigate to home screen
              return NavBarScreen();
            } else {
              // User is not signed in, navigate to login screen
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
