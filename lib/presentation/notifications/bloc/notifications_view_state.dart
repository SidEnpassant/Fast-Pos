import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/pos_notification.dart';

class NotificationsViewState extends Equatable {
  const NotificationsViewState({
    this.notifications = const [],
    this.loading = true,
  });

  final List<PosNotification> notifications;
  final bool loading;

  NotificationsViewState copyWith({
    List<PosNotification>? notifications,
    bool? loading,
  }) {
    return NotificationsViewState(
      notifications: notifications ?? this.notifications,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [notifications, loading];
}
