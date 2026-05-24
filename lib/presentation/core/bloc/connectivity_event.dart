import 'package:equatable/equatable.dart';

sealed class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

final class ConnectivityStarted extends ConnectivityEvent {
  const ConnectivityStarted();
}

final class ConnectivityStatusChanged extends ConnectivityEvent {
  const ConnectivityStatusChanged({required this.isOnline});

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}

final class ConnectivityPendingCountChanged extends ConnectivityEvent {
  const ConnectivityPendingCountChanged(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}
