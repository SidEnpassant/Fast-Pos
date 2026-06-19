import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/notifications/notification_sync_coordinator.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_bloc.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_flow_state.dart';

/// Starts OS notification sync when the user is signed in.
class NotificationBridgeListener extends StatefulWidget {
  const NotificationBridgeListener({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationBridgeListener> createState() =>
      _NotificationBridgeListenerState();
}

class _NotificationBridgeListenerState
    extends State<NotificationBridgeListener> {
  @override
  void initState() {
    super.initState();
    _syncIfAuthenticated();
  }

  void _syncIfAuthenticated() {
    final auth = context.read<AuthBloc>().state;
    if (auth.status != AuthFlowStatus.authenticated) return;
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<NotificationSyncCoordinator>().start(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthFlowState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) async {
        final coordinator = context.read<NotificationSyncCoordinator>();
        if (state.status == AuthFlowStatus.authenticated) {
          final uid = context.read<AuthRepository>().currentSession?.userId;
          if (uid != null) await coordinator.start(uid);
        } else {
          await coordinator.stop();
        }
      },
      child: widget.child,
    );
  }
}
