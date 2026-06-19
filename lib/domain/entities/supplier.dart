import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? email;
  final String? gstin;
  final String? address;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.gstin,
    this.address,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, userId, name, phone, email, gstin, address, updatedAt];
}