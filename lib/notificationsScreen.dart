import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user's ID safely
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: const Text('Please log in to view notifications.'),
      );
    }

    final userId = user.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: const Text('No notifications'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>?;

              // Check if data is null before accessing fields
              if (data == null) {
                return const ListTile(
                  title: Text('Error loading notification.'),
                );
              }

              final message = data['message'] as String?;
              final timestamp = data['timestamp'] as Timestamp?;

              return ListTile(
                title: Text(
                    message ?? 'No message available'), // Handle null message
                subtitle: Text(timestamp != null
                    ? DateFormat('yyyy-MM-dd – kk:mm')
                        .format(timestamp.toDate())
                    : 'Unknown time'), // Handle null timestamp
                onTap: () {
                  // Mark as read or navigate to relevant screen
                },
              );
            },
          );
        },
      ),
    );
  }
}
