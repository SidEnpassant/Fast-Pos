import 'package:equatable/equatable.dart';

enum StockAuditStatus { inProgress, completed, cancelled }

class StockAudit extends Equatable {
  final String id;
  final String userId;
  final DateTime auditDate;
  final StockAuditStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<StockAuditLine> lines;

  const StockAudit({
    required this.id,
    required this.userId,
    required this.auditDate,
    required this.status,
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.lines = const [],
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        auditDate,
        status,
        notes,
        createdAt,
        completedAt,
        lines,
      ];

  StockAudit copyWith({
    String? id,
    String? userId,
    DateTime? auditDate,
    StockAuditStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? completedAt,
    List<StockAuditLine>? lines,
  }) {
    return StockAudit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      auditDate: auditDate ?? this.auditDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      lines: lines ?? this.lines,
    );
  }
}

class StockAuditLine extends Equatable {
  final String id;
  final String auditId;
  final String productId;
  final String productName;
  final double systemQty;
  final double physicalQty;
  final double variance;
  final String? note;

  const StockAuditLine({
    required this.id,
    required this.auditId,
    required this.productId,
    required this.productName,
    required this.systemQty,
    required this.physicalQty,
    required this.variance,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        auditId,
        productId,
        productName,
        systemQty,
        physicalQty,
        variance,
        note,
      ];

  StockAuditLine copyWith({
    String? id,
    String? auditId,
    String? productId,
    String? productName,
    double? systemQty,
    double? physicalQty,
    double? variance,
    String? note,
  }) {
    return StockAuditLine(
      id: id ?? this.id,
      auditId: auditId ?? this.auditId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      systemQty: systemQty ?? this.systemQty,
      physicalQty: physicalQty ?? this.physicalQty,
      variance: variance ?? this.variance,
      note: note ?? this.note,
    );
  }
}