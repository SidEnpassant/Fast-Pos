import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/user_profile.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.profiles,
    this.bills,
  });

  final List<UserProfile>? profiles;
  final List<Bill>? bills;

  DashboardState copyWith({
    List<UserProfile>? profiles,
    List<Bill>? bills,
  }) {
    return DashboardState(
      profiles: profiles ?? this.profiles,
      bills: bills ?? this.bills,
    );
  }

  @override
  List<Object?> get props => [profiles, bills];
}
