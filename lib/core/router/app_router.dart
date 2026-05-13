import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/analytics/cubit/analytics_cubit.dart';
import 'package:inventopos/presentation/auth/cubit/auth_cubit.dart';
import 'package:inventopos/presentation/auth/cubit/auth_flow_state.dart';
import 'package:inventopos/presentation/dashboard/cubit/dashboard_cubit.dart';
import 'package:inventopos/presentation/notifications/cubit/notifications_cubit.dart';
import 'package:inventopos/presentation/shell/view/shell_page.dart';
import 'package:inventopos/screens/Account/myAccount.dart';
import 'package:inventopos/screens/Authentication/EmailVerificationScreen.dart';
import 'package:inventopos/screens/Authentication/forgotPassword.dart';
import 'package:inventopos/screens/Bill/BillGenerationScreen.dart';
import 'package:inventopos/screens/Dashboard/DashboardScreen.dart';
import 'package:inventopos/screens/Dashboard/MonthlyRevenueAnalysis.dart';
import 'package:inventopos/screens/Notification/notificationsScreen.dart';
import 'package:inventopos/screens/Transactions/CompleteTransactionsScreen.dart';
import 'package:inventopos/screens/Transactions/IncompleteTransactionsScreen.dart';
import 'package:inventopos/screens/login/loginScreen.dart';
import 'package:inventopos/screens/register/signUpScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Root navigator for full-screen routes that sit above the tab shell.
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Notifies [GoRouter] when [AuthCubit] emits so [redirect] re-runs.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(this._authCubit) {
    _subscription = _authCubit.stream.listen((_) => notifyListeners());
  }

  final AuthCubit _authCubit;
  late final StreamSubscription<AuthFlowState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter(AuthCubit auth, Listenable refresh) {
  return GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final status = auth.state.status;

      bool needsAuth(String p) {
        return p.startsWith('/app/') ||
            p == '/home' ||
            p == '/complete-transactions' ||
            p == '/incomplete-transactions';
      }

      if (status == AuthFlowStatus.unknown) {
        if (path != '/') return '/';
        return null;
      }

      if (status == AuthFlowStatus.unauthenticated) {
        if (path == '/') return '/login';
        if (needsAuth(path)) return '/login';
        const public = {
          '/login',
          '/signup',
          '/forgot-password',
          '/verify-email',
        };
        if (public.contains(path)) return null;
        return '/login';
      }

      // authenticated
      switch (path) {
        case '/home':
          return '/app/dashboard';
        case '/AnalyticsDashboard':
          return '/app/analysis';
        case '/create-bill':
          return '/app/new-bill';
        case '/profile':
          return '/app/profile';
        case '/notification':
          return '/app/notifications';
      }
      if (path == '/' ||
          path == '/login' ||
          path == '/signup' ||
          path == '/forgot-password') {
        return '/app/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const ForgotPassword(),
      ),
      GoRoute(
        path: '/verify-email',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return RegistrationSuccessScreen(
            email: email.isEmpty ? 'your email' : email,
          );
        },
      ),
      GoRoute(
        path: '/complete-transactions',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const CompleteTransactionsScreen(),
      ),
      GoRoute(
        path: '/incomplete-transactions',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const IncompleteTransactionsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/dashboard',
                builder: (context, state) => BlocProvider(
                  create: (ctx) => DashboardCubit(
                    ctx.read<BillsRepository>(),
                    ctx.read<ProfileRepository>(),
                  ),
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/analysis',
                builder: (context, state) => BlocProvider(
                  create: (ctx) => AnalyticsCubit(ctx.read<BillsRepository>()),
                  child: const MonthlyRevenueAnalysis(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/new-bill',
                builder: (context, state) => const BillGenerationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/notifications',
                builder: (context, state) {
                  final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
                  if (uid.isEmpty) {
                    return const Scaffold(
                      body: Center(child: Text('Please log in')),
                    );
                  }
                  return BlocProvider(
                    create: (ctx) => NotificationsCubit(
                      ctx.read<NotificationsRepository>(),
                      uid,
                    ),
                    child: const NotificationsScreen(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/profile',
                builder: (context, state) => const MyAccountPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
