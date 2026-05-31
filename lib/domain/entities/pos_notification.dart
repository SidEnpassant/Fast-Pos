import 'package:equatable/equatable.dart';

/// In-app notification row.
class PosNotification extends Equatable {
  const PosNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.dedupKey,
    this.type,
  });

  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? dedupKey;
  final String? type;

  @override
  List<Object?> get props =>
      [id, userId, message, timestamp, isRead, dedupKey, type];
}
