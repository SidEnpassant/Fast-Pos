import 'package:equatable/equatable.dart';

/// In-app notification row.
class PosNotification extends Equatable {
  const PosNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  @override
  List<Object?> get props => [id, userId, message, timestamp, isRead];
}
