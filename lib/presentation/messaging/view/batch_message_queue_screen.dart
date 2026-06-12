import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/messaging/list_pending_message_actions_use_case.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';
import 'package:inventopos/presentation/messaging/widgets/message_action_tile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BatchMessageQueueScreen extends StatelessWidget {
  const BatchMessageQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Queue'),
      ),
      body: BlocBuilder<DashboardHubBloc, DashboardHubState>(
        builder: (context, dashState) {
          final bills = dashState.bills;
          if (bills == null || (bills.isEmpty && dashState.loading)) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<List<OutboundMessage>>(
            future: _buildActions(context, bills),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final actions = snapshot.data ?? [];
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
          );
        },
      ),
    );
  }

  Future<List<OutboundMessage>> _buildActions(
      BuildContext context, List<Bill> bills) async {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    
    // Capture dependencies before async gap
    final prefsUseCase = context.read<ObserveAiPreferencesUseCase>();
    final profileUseCase = context.read<ObserveProfileForCurrentUserUseCase>();
    final pendingActionsUseCase = context.read<ListPendingMessageActionsUseCase>();

    final prefs = await prefsUseCase(uid).first;
    
    final profileStream = profileUseCase.call();
    List<UserProfile>? profileList;
    if (profileStream != null) {
      profileList = await profileStream.first;
    }
    
    String shopName = 'Our Shop';
    if (profileList != null && profileList.isNotEmpty) {
      shopName = profileList.first.businessName ?? 'Our Shop';
    }

    return pendingActionsUseCase(
      bills: bills,
      shopName: shopName,
      prefs: prefs,
    );
  }
}
