import 'package:flutter/material.dart';
import 'package:inventopos/screens/Account/myAccount.dart';
import 'package:inventopos/screens/Dashboard/MonthlyRevenueAnalysis.dart';
import 'package:inventopos/screens/bottom%20navigation%20bar/bottomNavbar.dart';
import 'package:inventopos/supabase_config.dart';
import 'package:inventopos/screens/Notification/notificationsScreen.dart';
import 'package:inventopos/screens/login/loginScreen.dart';
import 'package:inventopos/screens/Bill/BillGenerationScreen.dart';
import 'package:inventopos/screens/Transactions/CompleteTransactionsScreen.dart';
import 'package:inventopos/screens/Authentication/EmailVerificationScreen.dart';
import 'package:inventopos/screens/Transactions/IncompleteTransactionsScreen.dart';
import 'package:inventopos/screens/Authentication/forgotPassword.dart';
import 'package:inventopos/screens/register/signUpScreen.dart';
import 'package:inventopos/screens/splashScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fast Pos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
      routes: {
        '/verify-email': (context) => RegistrationSuccessScreen(
              email: ModalRoute.of(context)?.settings.arguments as String,
            ),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => RegisterScreen(),
        '/home': (context) => NavBarScreen(),
        '/forgot-password': (context) => ForgotPassword(),
        '/create-bill': (context) => BillGenerationScreen(),
        '/complete-transactions': (context) => CompleteTransactionsScreen(),
        '/incomplete-transactions': (context) => IncompleteTransactionsScreen(),
        '/profile': (context) => MyAccountPage(),
        '/notification': (context) => NotificationsScreen(),
        '/AnalyticsDashboard': (context) => MonthlyRevenueAnalysis(),
      },
    );
  }
}
