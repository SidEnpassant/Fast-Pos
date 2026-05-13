import 'package:equatable/equatable.dart';

class NotificationsViewState extends Equatable {
  const NotificationsViewState({
    this.rows = const [],
  });

  final List<Map<String, dynamic>> rows;

  NotificationsViewState copyWith({
    List<Map<String, dynamic>>? rows,
  }) {
    return NotificationsViewState(rows: rows ?? this.rows);
  }

  @override
  List<Object?> get props => [rows];
}
