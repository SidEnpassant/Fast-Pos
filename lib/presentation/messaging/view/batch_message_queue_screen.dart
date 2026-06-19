import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_bloc.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_event.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_state.dart';
import 'package:inventopos/presentation/messaging/widgets/message_action_tile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BatchMessageQueueScreen extends StatefulWidget {
  const BatchMessageQueueScreen({super.key});

  @override
  State<BatchMessageQueueScreen> createState() =>
      _BatchMessageQueueScreenState();
}

class _BatchMessageQueueScreenState extends State<BatchMessageQueueScreen> {
  @override
  void initState() {
    super.initState();
    _requestQueue();
  }

  Future<void> _requestQueue() async {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final prefs = await context.read<ObserveAiPreferencesUseCase>()(uid).first;
    final profileStream =
        context.read<ObserveProfileForCurrentUserUseCase>().call();
    final profileList =
        profileStream != null ? await profileStream.first : null;

    final shopName = profileList != null && profileList.isNotEmpty
        ? profileList.first.businessName ?? 'Our Shop'
        : 'Our Shop';

    if (mounted) {
      final bills = context.read<DashboardHubBloc>().state.bills ?? [];
      context.read<MessagingAutomationBloc>().add(
            MessagingBatchQueueRequested(
              bills: bills,
              shopName: shopName,
              prefs: prefs,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Queue'),
      ),
      body: BlocBuilder<MessagingAutomationBloc, MessagingAutomationState>(
        builder: (context, state) {
          if (state.queueLoading) {
            return const AppSkeletonList(itemCount: 8);
          }

          final actions = state.queue;
          if (actions.isEmpty) {
            return const Center(
              child: Text('No pending messages for today.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              return MessageActionTile(message: actions[index]);
            },
          );
        },
      ),
    );
  }
}
