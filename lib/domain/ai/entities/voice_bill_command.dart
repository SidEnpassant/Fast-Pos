import 'package:equatable/equatable.dart';

class VoiceBillLine extends Equatable {
  const VoiceBillLine({
    required this.productName,
    required this.quantity,
    this.productId,
  });

  final String productName;
  final int quantity;
  final String? productId;

  @override
  List<Object?> get props => [productName, quantity, productId];
}

class VoiceBillCommand extends Equatable {
  const VoiceBillCommand({
    this.customerHint,
    this.lines = const [],
  });

  final String? customerHint;
  final List<VoiceBillLine> lines;

  @override
  List<Object?> get props => [customerHint, lines];
}
