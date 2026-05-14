import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/user_profile.dart';

sealed class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class AccountProfilesReceived extends AccountEvent {
  const AccountProfilesReceived(this.profiles);

  final List<UserProfile> profiles;

  @override
  List<Object?> get props => [profiles];
}

class AccountFieldPatched extends AccountEvent {
  const AccountFieldPatched(this.field, this.value);

  final String field;
  final String value;

  @override
  List<Object?> get props => [field, value];
}

class AccountNoSession extends AccountEvent {
  const AccountNoSession();
}
