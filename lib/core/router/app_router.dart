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
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/account/bloc/account_bloc.dart';
import 'package:inventopos/presentation/account/view/my_account.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_bloc.dart';
import 'package:inventopos/presentation/analytics/view/monthly_revenue_analysis.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_flow_state.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_bloc.dart';
import 'package:inventopos/presentation/auth_login/view/login_screen.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_bloc.dart';
import 'package:inventopos/presentation/billing/view/bill_generation_page.dart';
import 'package:inventopos/presentation/billing/bloc/bill_inventory_picker_bloc.dart';
import 'package:inventopos/presentation/billing/view/bill_inventory_picker_page.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_bloc.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_scan_bloc.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/application/billing/lookup_product_name_by_barcode_use_case.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_bloc.dart';
import 'package:inventopos/presentation/inventory/view/inventory_screen.dart';
import 'package:inventopos/presentation/expenses/bloc/expenses_bloc.dart';
import 'package:inventopos/presentation/expenses/view/expenses_screen.dart';
import 'package:inventopos/presentation/customers/bloc/customer_detail_bloc.dart';
import 'package:inventopos/presentation/customers/view/customer_detail_screen.dart';
import 'package:inventopos/presentation/customers/view/customers_screen.dart';
import 'package:inventopos/presentation/printer_setup/view/printer_setup_page.dart';
import 'package:inventopos/presentation/import_export/view/import_export_page.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/view/dashboard_screen.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_bloc.dart';
import 'package:inventopos/presentation/notifications/view/notifications_screen.dart';
import 'package:inventopos/presentation/inventory/view/product_editor_page.dart';
import 'package:inventopos/application/billing/resolve_product_for_barcode_use_case.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_hub_bloc.dart';
import 'package:inventopos/presentation/analytics/view/analytics_suite_screen.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:inventopos/presentation/forgot_password/view/forgot_password_page.dart';
import 'package:inventopos/presentation/register/bloc/register_bloc.dart';
import 'package:inventopos/presentation/register/view/register_screen.dart';
import 'package:inventopos/presentation/registration_success/bloc/registration_success_bloc.dart';
import 'package:inventopos/presentation/registration_success/view/registration_success_screen.dart';
import 'package:inventopos/presentation/shell/view/shell_page.dart';
import 'package:inventopos/presentation/transactions/view/complete_transaction/complete_transactions_screen.dart';
import 'package:inventopos/presentation/transactions/view/incomplete_transaction/incomplete_transactions_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        case '/app/inventory':
          return null;
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
      GoRoute(
        path: '/expenses',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => BlocProvider(
          create: (ctx) => ExpensesBloc(ctx.read<ExpenseRepository>()),
          child: const ExpensesScreen(),
        ),
      ),
      GoRoute(
        path: '/customers',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => BlocProvider(
          create: (ctx) => CustomerDetailBloc(
            ctx.read<CustomerRepository>(),
            ctx.read<BillsRepository>(),
          ),
          child: CustomerDetailScreen(
            customerId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/inventory/editor',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          return ProductEditorPage(productId: extra as String?);
        },
      ),
      GoRoute(
        path: '/printer-setup',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const PrinterSetupPage(),
      ),
      GoRoute(
        path: '/import-export',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const ImportExportPage(),
      ),
      GoRoute(
        path: '/app/bill/inventory-picker',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final draftLines = extra is List<BillDraftLine>
              ? extra
              : extra is List
                  ? List<BillDraftLine>.from(extra.cast<BillDraftLine>())
                  : const <BillDraftLine>[];
          return BlocProvider(
            create: (ctx) =>
                BillInventoryPickerBloc(ctx.read<ProductRepository>()),
            child: BillInventoryPickerPage(existingDraftLines: draftLines),
          );
        },
      ),
      GoRoute(
        path: '/app/notifications',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (ctx, state) {
          final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
          return BlocProvider(
            create: (_) => NotificationsBloc(
              ctx.read<NotificationsRepository>(),
              uid,
            ),
            child: const NotificationsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/app/profile',
        parentNavigatorKey: appRootNavigatorKey,
        builder: (ctx, state) => BlocProvider(
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
                  create: (ctx) => DashboardHubBloc(
                    ctx.read<ObserveBillsUseCase>(),
                    ctx.read<ProfileRepository>(),
                    ctx.read<ProductRepository>(),
                    ctx.read<ExpenseRepository>(),
                    ctx.read<CustomerRepository>(),
                    ctx.read<SyncRepository>(),
                    ctx.read<NotificationsRepository>(),
                  ),
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/inventory',
                builder: (context, state) => BlocProvider(
                  create: (ctx) => InventoryBloc(ctx.read<ProductRepository>()),
                  child: const InventoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/new-bill',
                builder: (context, state) => BlocProvider(
                  create: (_) => BillVoiceAssistBloc(SpeechToText()),
                  child: BlocProvider(
                    create: (ctx) => BillSubmissionBloc(
                      ctx.read<SubmitBillUseCase>(),
                    ),
                    child: BlocProvider(
                      create: (_) => BillDraftBloc(),
                      child: BlocProvider(
                        create: (_) => CheckoutBloc(),
                        child: BlocProvider(
                          create: (ctx) => CheckoutScanBloc(
                            ctx.read<ResolveProductForBarcodeUseCase>(),
                          ),
                          child: const BillGenerationPage(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/analysis',
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (ctx) =>
                          AnalyticsBloc(ctx.read<ObserveBillsUseCase>()),
                    ),
                    BlocProvider(
                      create: (ctx) => AnalyticsHubBloc(
                        ctx.read<ObserveBillsUseCase>(),
                        ctx.read<ExpenseRepository>(),
                        ctx.read<ProductRepository>(),
                      ),
                    ),
                  ],
                  child: const AnalyticsSuiteScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
