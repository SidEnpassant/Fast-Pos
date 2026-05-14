import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';

class NotificationsViewState extends Equatable {
  const NotificationsViewState({
    this.notifications = const [],
  });

  final List<PosNotification> notifications;

  NotificationsViewState copyWith({
    List<PosNotification>? notifications,
  }) {
    return NotificationsViewState(
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [notifications];
}
