import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/supabase_mappers.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Center(
        child: const Text('Please log in to view notifications.'),
      );
    }

    final userId = user.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('notifications')
            .stream(primaryKey: ['id']).eq('user_id', userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: const Text(
                'No notifications',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final rows = List<Map<String, dynamic>>.from(snapshot.data!);
          rows.sort((a, b) => SupabaseMappers.parseDate(b['timestamp'])
              .compareTo(SupabaseMappers.parseDate(a['timestamp'])));

          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final data = SupabaseMappers.notificationFromRow(row);
              final id = row['id'] as String;

              final message = data['message'] as String?;
              final timestamp = data['timestamp'] as DateTime?;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                      await Supabase.instance.client
                          .from('notifications')
                          .delete()
                          .eq('id', id);
                      await _showToast('Notification deleted');
                    } catch (e) {
                      await _showToast('Failed to delete notification: $e');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 223, 232, 247)
                              .withOpacity(0.7),
                          const Color.fromARGB(255, 233, 234, 235)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading:
                          Icon(Icons.notifications, color: Colors.blueAccent),
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
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () async {
                        await _showToast(message ?? 'No message available');
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
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
      print('Toast error: $e');
    }
  }
}
