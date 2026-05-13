import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/presentation/notifications/cubit/notifications_view_state.dart';

class NotificationsCubit extends Cubit<NotificationsViewState> {
  NotificationsCubit(this._repository, this._userId)
      : super(const NotificationsViewState()) {
    _sub = _repository.watchNotifications(_userId).listen(
          (rows) => emit(state.copyWith(rows: rows)),
        );
  }

  final NotificationsRepository _repository;
  final String _userId;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  Future<void> deleteNotification(String id) =>
      _repository.deleteNotification(id);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
