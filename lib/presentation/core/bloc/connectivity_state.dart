import 'package:equatable/equatable.dart';

class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.isOnline = true,
    this.pendingSyncCount = 0,
  });

  final bool isOnline;
  final int pendingSyncCount;

  ConnectivityState copyWith({bool? isOnline, int? pendingSyncCount}) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }

  @override
  List<Object?> get props => [isOnline, pendingSyncCount];
}
