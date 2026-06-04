import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/ai/replay_offline_ai_queue_use_case.dart';
import 'package:inventopos/core/notifications/notification_background_poll.dart'
    show NotificationBackgroundPoll, consumeBackgroundPollPending;
import 'package:inventopos/core/notifications/notification_sync_coordinator.dart';
import 'package:inventopos/data/sync/sync_coordinator.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_flow_state.dart';

/// Starts sync coordinator and replays offline AI queue when authenticated.
class AiAutomationBridgeListener extends StatefulWidget {
  const AiAutomationBridgeListener({super.key, required this.child});

  final Widget child;

  @override
  State<AiAutomationBridgeListener> createState() =>
      _AiAutomationBridgeListenerState();
}

class _AiAutomationBridgeListenerState extends State<AiAutomationBridgeListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthenticated());
  }

  Future<void> _onAuthenticated() async {
    final auth = context.read<AuthBloc>().state;
    if (auth.status != AuthFlowStatus.authenticated) return;
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid == null) return;

    context.read<SyncCoordinator>().start(uid);
    await context.read<ReplayOfflineAiQueueUseCase>()(uid);
    if (await consumeBackgroundPollPending()) {
      await NotificationBackgroundPoll.pollWith(
        userId: uid,
        repository: context.read<NotificationsRepository>(),
        coordinator: context.read<NotificationSyncCoordinator>(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthFlowState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) async {
        if (state.status == AuthFlowStatus.authenticated) {
          await _onAuthenticated();
        }
      },
      child: widget.child,
    );
  }
}
