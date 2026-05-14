import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_event.dart';
import 'package:inventopos/presentation/notifications/bloc/notifications_view_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsViewState> {
  NotificationsBloc(this._repository, this._userId)
      : super(const NotificationsViewState()) {
    on<NotificationsReceived>(_onReceived);
    on<NotificationsDeleteRequested>(_onDeleteRequested);

    _sub = _repository.watchNotifications(_userId).listen(
          (list) => add(NotificationsReceived(list)),
        );
  }

  final NotificationsRepository _repository;
  final String _userId;
  StreamSubscription<dynamic>? _sub;

  Future<void> deleteNotification(String id) async {
    add(NotificationsDeleteRequested(id));
  }

  Future<void> _onDeleteRequested(
    NotificationsDeleteRequested event,
    Emitter<NotificationsViewState> emit,
  ) async {
    await _repository.deleteNotification(event.id);
  }

  void _onReceived(
    NotificationsReceived event,
    Emitter<NotificationsViewState> emit,
  ) {
    emit(state.copyWith(notifications: event.notifications));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
