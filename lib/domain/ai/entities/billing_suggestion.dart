import 'package:equatable/equatable.dart';

class BillingSuggestion extends Equatable {
  const BillingSuggestion({
    required this.productId,
    required this.reason,
    this.productName,
  });

  final String productId;
  final String reason;
  final String? productName;

  @override
  List<Object?> get props => [productId, reason, productName];
}
