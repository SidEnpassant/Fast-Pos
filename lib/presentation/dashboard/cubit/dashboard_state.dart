import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.profileRows,
    this.billsRows,
  });

  final List<Map<String, dynamic>>? profileRows;
  final List<Map<String, dynamic>>? billsRows;

  DashboardState copyWith({
    List<Map<String, dynamic>>? profileRows,
    List<Map<String, dynamic>>? billsRows,
  }) {
    return DashboardState(
      profileRows: profileRows ?? this.profileRows,
      billsRows: billsRows ?? this.billsRows,
    );
  }

  @override
  List<Object?> get props => [profileRows, billsRows];
}
