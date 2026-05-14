import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

final class NotificationsReceived extends NotificationsEvent {
  const NotificationsReceived(this.notifications);

  final List<PosNotification> notifications;

  @override
  List<Object?> get props => [notifications];
}

final class NotificationsDeleteRequested extends NotificationsEvent {
  const NotificationsDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
