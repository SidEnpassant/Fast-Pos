import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/loyalty/loyalty_config.dart';

enum LoyaltyStatus { initial, loading, success, failure }

class LoyaltyState extends Equatable {
  const LoyaltyState({
    this.status = LoyaltyStatus.initial,
    this.config = const LoyaltyConfig(),
    this.error,
  });

  final LoyaltyStatus status;
  final LoyaltyConfig config;
  final String? error;

  @override
  List<Object?> get props => [status, config, error];

  LoyaltyState copyWith({
    LoyaltyStatus? status,
    LoyaltyConfig? config,
    String? error,
  }) {
    return LoyaltyState(
      status: status ?? this.status,
      config: config ?? this.config,
      error: error ?? this.error,
    );
  }
}
