import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/loyalty/loyalty_config.dart';

abstract class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();
  @override
  List<Object?> get props => [];
}

class LoadLoyaltyConfig extends LoyaltyEvent {
  final String userId;
  const LoadLoyaltyConfig(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SaveLoyaltyConfig extends LoyaltyEvent {
  final String userId;
  final LoyaltyConfig config;
  const SaveLoyaltyConfig(this.userId, this.config);
  @override
  List<Object?> get props => [userId, config];
}
