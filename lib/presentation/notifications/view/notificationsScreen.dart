import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_bloc.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_view_state.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
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
            child: BlocBuilder<NotificationsBloc, NotificationsViewState>(
              builder: (context, state) {
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
                  ..sort(
                    (a, b) => b.timestamp.compareTo(a.timestamp),
                  );

                return ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final n = sorted[index];
                    final id = n.id;

                    final message = n.message;
                    final timestamp = n.timestamp;

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
                                .read<NotificationsBloc>()
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
                              message.isEmpty ? 'No message available' : message,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('yyyy-MM-dd – kk:mm').format(timestamp),
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            onTap: () async {
                              await _showToast(
                                message.isEmpty
                                    ? 'No message available'
                                    : message,
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
