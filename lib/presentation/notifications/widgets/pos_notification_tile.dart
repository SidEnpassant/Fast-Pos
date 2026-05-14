import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_bloc.dart';

class PosNotificationTile extends StatelessWidget {
  const PosNotificationTile({super.key, required this.notification});

  final PosNotification notification;

  static Future<void> showToast(String message) async {
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

  @override
  Widget build(BuildContext context) {
    final id = notification.id;
    final message = notification.message;
    final timestamp = notification.timestamp;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
            await context.read<NotificationsBloc>().deleteNotification(id);
            await showToast('Notification deleted');
          } catch (e) {
            await showToast('Failed to delete notification: $e');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 223, 232, 247).withValues(alpha: 0.7),
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
              await showToast(
                message.isEmpty ? 'No message available' : message,
              );
            },
          ),
        ),
      ),
    );
  }
}
