import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_bloc.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_view_state.dart';
import 'package:inventopos/presentation/notifications/widgets/pos_notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
        style: TextStyle(
          fontSize: 20,
         ),
        ),
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsViewState>(
        builder: (context, state) {
          if (state.loading) {
            return const AppSkeletonList(itemCount: 10);
          }
          final list = state.notifications;
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No notifications',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final sorted = List<PosNotification>.from(list)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              return PosNotificationTile(notification: sorted[index]);
            },
          );
        },
      ),
    );
  }
}
