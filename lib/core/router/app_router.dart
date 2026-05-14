import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/application/auth/request_password_reset_use_case.dart';
import 'package:inventopos/application/auth/sign_in_use_case.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/billing/submit_bill_use_case.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/application/profile/patch_account_profile_field_use_case.dart';
import 'package:inventopos/application/profile/replace_account_signature_use_case.dart';
import 'package:inventopos/application/registration/register_account_use_case.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/account/bloc/account_bloc.dart';
import 'package:inventopos/presentation/account/view/myAccount.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_bloc.dart';
import 'package:inventopos/presentation/analytics/view/MonthlyRevenueAnalysis.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_flow_state.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_bloc.dart';
import 'package:inventopos/presentation/auth_login/view/loginScreen.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_bloc.dart';
import 'package:inventopos/presentation/billing/view/bill_generation_page.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:inventopos/presentation/dashboard/view/dashboard_screen.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:inventopos/presentation/forgot_password/view/forgot_password_page.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_bloc.dart';
import 'package:inventopos/presentation/notifications/view/notificationsScreen.dart';
import 'package:inventopos/presentation/register/bloc/register_bloc.dart';
import 'package:inventopos/presentation/register/view/register_screen.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_bloc.dart';
import 'package:inventopos/presentation/registration_success/view/registration_success_screen.dart';
import 'package:inventopos/presentation/shell/view/shell_page.dart';
import 'package:inventopos/presentation/transactions/view/complete_transaction/CompleteTransactionsScreen.dart';
import 'package:inventopos/presentation/transactions/view/incomplete_transaction/IncompleteTransactionsScreen.dart';

/// Root navigator for full-screen routes that sit above the tab shell.
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Notifies [GoRouter] when [AuthBloc] emits so [redirect] re-runs.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) {
      // Defer so [GoRouter] does not refresh during another widget's build or
      // during router delegate updates (avoids setState-during-build asserts).
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    });
  }

  final AuthBloc _authBloc;
  late final StreamSubscription<AuthFlowState> _subscription;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter(AuthBloc auth, Listenable refresh) {
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
        builder: (context, state) => BlocProvider(
          create: (ctx) => LoginBloc(ctx.read<SignInUseCase>()),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => BlocProvider(
          create: (ctx) => RegisterBloc(ctx.read<RegisterAccountUseCase>()),
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => BlocProvider(
          create: (ctx) =>
              ForgotPasswordBloc(ctx.read<RequestPasswordResetUseCase>()),
          child: const ForgotPassword(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return BlocProvider(
            create: (_) => RegistrationSuccessBloc(),
            child: RegistrationSuccessScreen(
              email: email.isEmpty ? 'your email' : email,
            ),
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
                  create: (ctx) => DashboardBloc(
                    ctx.read<ObserveBillsUseCase>(),
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
                  create: (ctx) =>
                      AnalyticsBloc(ctx.read<ObserveBillsUseCase>()),
                  child: const MonthlyRevenueAnalysis(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/new-bill',
                builder: (context, state) => BlocProvider(
                  create: (ctx) => BillSubmissionBloc(
                    ctx.read<SubmitBillUseCase>(),
                  ),
                  child: BlocProvider(
                    create: (_) => BillDraftBloc(),
                    child: const BillGenerationPage(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/notifications',
                builder: (context, state) {
                  final uid =
                      context.read<AuthRepository>().currentSession?.userId ??
                          '';
                  if (uid.isEmpty) {
                    return const Scaffold(
                      body: Center(child: Text('Please log in')),
                    );
                  }
                  return BlocProvider(
                    create: (ctx) => NotificationsBloc(
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
                builder: (context, state) => BlocProvider(
                  create: (ctx) => AccountBloc(
                    ctx.read<ObserveProfileForCurrentUserUseCase>(),
                    ctx.read<PatchAccountProfileFieldUseCase>(),
                    ctx.read<ReplaceAccountSignatureUseCase>(),
                    ctx.read<ProfileRepository>(),
                    ctx.read<AuthRepository>(),
                  ),
                  child: const MyAccountPage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
