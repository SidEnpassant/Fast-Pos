import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/router/app_router.dart';
import 'package:inventopos/core/theme/app_theme.dart';
import 'package:inventopos/data/repositories/auth_repository_impl.dart';
import 'package:inventopos/data/repositories/bills_repository_impl.dart';
import 'package:inventopos/data/repositories/notifications_repository_impl.dart';
import 'package:inventopos/data/repositories/profile_repository_impl.dart';
import 'package:inventopos/data/repositories/transactions_repository_impl.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/transactions_repository.dart';
import 'package:inventopos/presentation/auth/cubit/auth_cubit.dart';
import 'package:inventopos/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final authRepository = AuthRepositoryImpl();
  final billsRepository = BillsRepositoryImpl();
  final profileRepository = ProfileRepositoryImpl();
  final notificationsRepository = NotificationsRepositoryImpl();
  final transactionsRepository = TransactionsRepositoryImpl();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<BillsRepository>.value(value: billsRepository),
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
        RepositoryProvider<NotificationsRepository>.value(
          value: notificationsRepository,
        ),
        RepositoryProvider<TransactionsRepository>.value(
          value: transactionsRepository,
        ),
      ],
      child: BlocProvider(
        create: (_) => AuthCubit(authRepository),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AuthRouterRefresh? _authRefresh;
  GoRouter? _router;

  @override
  void dispose() {
    _authRefresh?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>();
    _authRefresh ??= AuthRouterRefresh(auth);
    _router ??= createAppRouter(auth, _authRefresh!);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fast Pos',
      theme: AppTheme.light(),
      routerConfig: _router!,
    );
  }
}
