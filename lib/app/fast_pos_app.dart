import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/app/app_providers.dart';
import 'package:inventopos/application/ai/replay_offline_ai_queue_use_case.dart';
import 'package:inventopos/application/auth/sign_out_use_case.dart';
import 'package:inventopos/core/router/app_router.dart';
import 'package:inventopos/core/theme/app_theme.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_event.dart';
import 'package:inventopos/presentation/core/widgets/ai_automation_bridge_listener.dart';
import 'package:inventopos/presentation/core/widgets/notification_bridge_listener.dart';

/// Repositories + global [AuthBloc] — pass to [runApp].
Widget fastPosRoot() {
  return MultiRepositoryProvider(
    providers: appRepositoryProviders(),
    child: BlocProvider(
      create: (c) => ConnectivityBloc(
        c.read<SyncRepository>(),
        c.read<ReplayOfflineAiQueueUseCase>(),
      )
        ..add(const ConnectivityStarted()),
      child: BlocProvider(
        create: (c) => AuthBloc(
          c.read<AuthRepository>(),
          c.read<SignOutUseCase>(),
        ),
        child: const FastPosApp(),
      ),
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
  void dispose() {
    _authRefresh?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>();
    _authRefresh ??= AuthRouterRefresh(auth);
    _router ??= createAppRouter(auth, _authRefresh!);

    return NotificationBridgeListener(
      child: AiAutomationBridgeListener(
        child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Fast Pos',
        theme: AppTheme.light(),
        routerConfig: _router!,
        ),
      ),
    );
  }
}
