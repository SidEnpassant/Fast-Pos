import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/app/app_providers.dart';
import 'package:inventopos/application/ai/build_briefing_metrics_use_case.dart';
import 'package:inventopos/application/ai/observe_ai_insights_use_case.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/ai/replay_offline_ai_queue_use_case.dart';
import 'package:inventopos/application/ai/run_daily_business_brief_use_case.dart';
import 'package:inventopos/application/auth/sign_out_use_case.dart';
import 'package:inventopos/application/automation/automation_use_cases.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/daybook/compute_day_book_use_case.dart';
import 'package:inventopos/application/daybook/record_cash_entry_use_case.dart';
import 'package:inventopos/application/inventory/evaluate_reorder_alerts_use_case.dart';
import 'package:inventopos/application/messaging/build_message_use_cases.dart';
import 'package:inventopos/application/messaging/list_pending_message_actions_use_case.dart';
import 'package:inventopos/application/returns/process_return_use_case.dart';
import 'package:inventopos/application/stock_audit/complete_stock_audit_use_case.dart';
import 'package:inventopos/application/stock_audit/start_stock_audit_use_case.dart';
import 'package:inventopos/core/router/app_router.dart';
import 'package:inventopos/core/theme/app_theme.dart';
import 'package:inventopos/domain/ai/repositories/ai_insights_port.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/domain/repositories/loyalty_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/stock_audit_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_flow_state.dart';
import 'package:inventopos/presentation/bill_sanity/bloc/bill_sanity_check_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/receipt_automation_bloc.dart';
import 'package:inventopos/presentation/collections_automation/bloc/collections_automation_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_event.dart';
import 'package:inventopos/presentation/core/widgets/ai_automation_bridge_listener.dart';
import 'package:inventopos/presentation/core/widgets/notification_bridge_listener.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_event.dart';
import 'package:inventopos/presentation/day_operations/bloc/day_operations_bloc.dart';
import 'package:inventopos/presentation/daybook/bloc/daybook_bloc.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_bloc.dart';
import 'package:inventopos/presentation/inventory_automation/bloc/inventory_automation_bloc.dart';
import 'package:inventopos/presentation/loyalty/bloc/loyalty_bloc.dart';
import 'package:inventopos/presentation/loyalty/bloc/loyalty_event.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_bloc.dart';
import 'package:inventopos/presentation/returns/bloc/return_bloc.dart';
import 'package:inventopos/presentation/stock_audit/bloc/stock_audit_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Repositories + global Blocs — pass to [runApp].
Widget fastPosRoot() {
  return MultiRepositoryProvider(
    providers: appRepositoryProviders(),
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (c) => ConnectivityBloc(
            c.read<SyncRepository>(),
            c.read<ReplayOfflineAiQueueUseCase>(),
          )..add(const ConnectivityStarted()),
        ),
        BlocProvider(
          create: (c) => AuthBloc(
            c.read<AuthRepository>(),
            c.read<SignOutUseCase>(),
          ),
        ),
        // App-wide data and automation blocs
        BlocProvider(
          create: (ctx) => DashboardHubBloc(
            ctx.read<ObserveBillsUseCase>(),
            ctx.read<ProfileRepository>(),
            ctx.read<ProductRepository>(),
            ctx.read<ExpenseRepository>(),
            ctx.read<CustomerRepository>(),
            ctx.read<SyncRepository>(),
            ctx.read<NotificationsRepository>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => InventoryAutomationBloc(
            ctx.read<EvaluateReorderAlertsUseCase>(),
            ctx.read<ObserveAiPreferencesUseCase>(),
            ctx.read<EvaluateDeadStockUseCase>(),
            ctx.read<EvaluateMarginLeaksUseCase>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => MessagingAutomationBloc(
            ctx.read<LaunchOutboundMessageUseCase>(),
            ctx.read<ListPendingMessageActionsUseCase>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => CollectionsAutomationBloc(
            ctx.read<EvaluateCreditExposureUseCase>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => DayOperationsBloc(
            ctx.read<BuildOpeningSnapshotUseCase>(),
            ctx.read<BuildEodSummaryUseCase>(),
            ctx.read<EvaluateExpenseSpikeUseCase>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => BusinessInsightsAiBloc(
            ctx.read<RunDailyBusinessBriefUseCase>(),
            ctx.read<BuildBriefingMetricsUseCase>(),
            ctx.read<ObserveAiInsightsUseCase>(),
            ctx.read<AiInsightsPort>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => BillSanityCheckBloc(
            ctx.read<EvaluateBillSanityUseCase>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => ReceiptAutomationBloc(
            buildReceipt: ctx.read<BuildReceiptMessageUseCase>(),
            buildThankYou: ctx.read<BuildPaymentThankYouMessageUseCase>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => ReturnBloc(
            ctx.read<BillsRepository>(),
            ctx.read<ProcessReturnUseCase>(),
            ctx.read<AuthRepository>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => StockAuditBloc(
            stockAuditRepository: ctx.read<StockAuditRepository>(),
            startStockAuditUseCase: ctx.read<StartStockAuditUseCase>(),
            completeStockAuditUseCase: ctx.read<CompleteStockAuditUseCase>(),
            authRepository: ctx.read<AuthRepository>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => DayBookBloc(
            computeDayBook: ctx.read<ComputeDayBookUseCase>(),
            recordCashEntry: ctx.read<RecordCashEntryUseCase>(),
            auth: ctx.read<AuthRepository>(),
          ),
        ),
        BlocProvider(
          create: (ctx) => LoyaltyBloc(
            repository: ctx.read<LoyaltyRepository>(),
          ),
        ),
      ],
      child: const FastPosApp(),
    ),
  );
}

/// [MaterialApp.router] + [GoRouter] bound to [AuthBloc] refresh stream.
class FastPosApp extends StatefulWidget {
  const FastPosApp({super.key});

  @override
  State<FastPosApp> createState() => _FastPosAppState();
}

class _FastPosAppState extends State<FastPosApp> {
  AuthRouterRefresh? _authRefresh;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _initHubIfAuthenticated();
    FlutterNativeSplash.remove();
  }

  void _initHubIfAuthenticated() {
    final auth = context.read<AuthBloc>().state;
    if (auth.status == AuthFlowStatus.authenticated) {
      final uid = context.read<AuthRepository>().currentSession?.userId;
      if (uid != null) {
        context.read<DashboardHubBloc>().add(DashboardHubStarted(uid));
        context.read<ConnectivityBloc>().add(const ConnectivityStarted());
        context.read<DayBookBloc>().add(DayBookStarted());
        context.read<LoyaltyBloc>().add(LoadLoyaltyConfig(uid));
        context.read<StockAuditBloc>().add(LoadStockAudits());
      }
    }
  }

  @override
  void dispose() {
    _authRefresh?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>();
    _authRefresh ??= AuthRouterRefresh(auth);
    _router ??= createAppRouter(auth, _authRefresh!);

    return BlocListener<AuthBloc, AuthFlowState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AuthFlowStatus.authenticated) {
          final uid = context.read<AuthRepository>().currentSession?.userId;
          if (uid != null) {
            context.read<DashboardHubBloc>().add(DashboardHubStarted(uid));
            context.read<ConnectivityBloc>().add(const ConnectivityStarted());
            context.read<DayBookBloc>().add(DayBookStarted());
            context.read<LoyaltyBloc>().add(LoadLoyaltyConfig(uid));
            context.read<StockAuditBloc>().add(LoadStockAudits());
          }
        }
      },
      child: NotificationBridgeListener(
        child: AiAutomationBridgeListener(
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, child) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'Fast Pos',
                theme: AppTheme.light(),
                routerConfig: _router!,
              );
            },
          ),
        ),
      ),
    );
  }
}
