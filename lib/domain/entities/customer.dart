import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.creditBalance = 0,
    this.loyaltyPoints = 0,
    this.lifetimePoints = 0,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  final String id;
  final String userId;
  final String name;
  final String? phone;
  final double creditBalance;
  final int loyaltyPoints;
  final int lifetimePoints;
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
        lifetimePoints,
        updatedAt,
        syncStatus,
      ];

  Customer copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    double? creditBalance,
    int? loyaltyPoints,
    int? lifetimePoints,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      creditBalance: creditBalance ?? this.creditBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
