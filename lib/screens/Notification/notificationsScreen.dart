import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/presentation/notifications/cubit/notifications_cubit.dart';
import 'package:inventopos/presentation/notifications/cubit/notifications_view_state.dart';
import 'package:inventopos/supabase_mappers.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to view notifications.'),
      );
    }

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBar(
            title: Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 25,
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: true,
          ),
          Expanded(
            child: BlocBuilder<NotificationsCubit, NotificationsViewState>(
              builder: (context, state) {
                final rows = state.rows;
                if (rows.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final sorted = List<Map<String, dynamic>>.from(rows)
                  ..sort(
                    (a, b) => SupabaseMappers.parseDate(b['timestamp'])
                        .compareTo(SupabaseMappers.parseDate(a['timestamp'])),
                  );

                return ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final row = sorted[index];
                    final data = SupabaseMappers.notificationFromRow(row);
                    final id = row['id'] as String;

                    final message = data['message'] as String?;
                    final timestamp = data['timestamp'] as DateTime?;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Dismissible(
                        key: Key(id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          try {
                            await context
                                .read<NotificationsCubit>()
                                .deleteNotification(id);
                            await _showToast('Notification deleted');
                          } catch (e) {
                            await _showToast(
                              'Failed to delete notification: $e',
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 223, 232, 247)
                                    .withValues(alpha: 0.7),
                                const Color.fromARGB(255, 233, 234, 235),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications,
                              color: Colors.blueAccent,
                            ),
                            title: Text(
                              message ?? 'No message available',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              timestamp != null
                                  ? DateFormat('yyyy-MM-dd – kk:mm')
                                      .format(timestamp)
                                  : 'Unknown time',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            onTap: () async {
                              await _showToast(
                                message ?? 'No message available',
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showToast(String message) async {
    try {
      await Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      debugPrint('Toast error: $e');
    }
  }
}
