import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventopos/Account/myAccount.dart';
import 'package:inventopos/firebase_options.dart';
import 'package:inventopos/notificationsScreen.dart';
import 'package:inventopos/screens/Authentication/loginScreen.dart';
import 'package:inventopos/screens/Bill/BillGenerationScreen.dart';
import 'package:inventopos/screens/Transactions/CompleteTransactionsScreen.dart';
import 'package:inventopos/screens/DashboardScreen.dart';
import 'package:inventopos/screens/Authentication/EmailVerificationScreen.dart';
import 'package:inventopos/screens/Transactions/IncompleteTransactionsScreen.dart';
import 'package:inventopos/screens/Authentication/forgotPassword.dart';
import 'package:inventopos/screens/Authentication/signUpScreen.dart';
import 'package:inventopos/screens/splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InventoPos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
      // Define routes here
      routes: {
        '/verify-email': (context) => EmailVerificationScreen(
              email: ModalRoute.of(context)?.settings.arguments as String,
            ),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => RegisterScreen(),
        '/home': (context) => DashboardScreen(),
        '/forgot-password': (context) => ForgotPassword(),
        '/create-bill': (context) => BillGenerationScreen(),
        '/complete-transactions': (context) => CompleteTransactionsScreen(),
        '/incomplete-transactions': (context) => IncompleteTransactionsScreen(),
        '/profile': (context) => MyAccountPage(),
        '/notification': (context) => NotificationsScreen(),
      },
    );
  }
}
