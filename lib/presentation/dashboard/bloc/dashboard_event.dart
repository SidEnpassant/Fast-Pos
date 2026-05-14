import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/user_profile.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

final class DashboardBillsReceived extends DashboardEvent {
  const DashboardBillsReceived(this.bills);

  final List<Bill> bills;

  @override
  List<Object?> get props => [bills];
}

final class DashboardProfileReceived extends DashboardEvent {
  const DashboardProfileReceived(this.profiles);

  final List<UserProfile> profiles;

  @override
  List<Object?> get props => [profiles];
}
