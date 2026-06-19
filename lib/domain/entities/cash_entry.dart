import 'package:equatable/equatable.dart';

class CashEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime entryDate;
  final String type; // sale_cash, payment_received, expense, supplier_payment, adjustment
  final double amount;
  final String? referenceId;
  final String? referenceType;
  final String? note;
  final DateTime createdAt;

  const CashEntry({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.type,
    required this.amount,
    this.referenceId,
    this.referenceType,
    this.note,
    required this.createdAt,
  });

  CashEntry copyWith({
    String? id,
    String? userId,
    DateTime? entryDate,
    String? type,
    double? amount,
    String? referenceId,
    String? referenceType,
    String? note,
    DateTime? createdAt,
  }) {
    return CashEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entryDate: entryDate ?? this.entryDate,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, entryDate, type, amount, referenceId, referenceType, note, createdAt];
}