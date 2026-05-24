import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.creditBalance = 0,
    this.loyaltyPoints = 0,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  final String id;
  final String userId;
  final String name;
  final String? phone;
  final double creditBalance;
  final int loyaltyPoints;
  final DateTime updatedAt;
  final String syncStatus;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        phone,
        creditBalance,
        loyaltyPoints,
        updatedAt,
        syncStatus,
      ];
}
