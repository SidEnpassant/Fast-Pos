import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/user_profile.dart';

sealed class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

final class AccountProfilesReceived extends AccountEvent {
  const AccountProfilesReceived(this.profiles);

  final List<UserProfile> profiles;

  @override
  List<Object?> get props => [profiles];
}

final class AccountFieldPatched extends AccountEvent {
  const AccountFieldPatched(this.field, this.value);

  final String field;
  final String value;

  @override
  List<Object?> get props => [field, value];
}

final class AccountPatchFieldRequested extends AccountEvent {
  const AccountPatchFieldRequested({
    required this.fieldKey,
    required this.value,
  });

  final String fieldKey;
  final String value;

  @override
  List<Object?> get props => [fieldKey, value];
}

final class AccountReplaceSignatureRequested extends AccountEvent {
  const AccountReplaceSignatureRequested(this.localFilePath);

  final String localFilePath;

  @override
  List<Object?> get props => [localFilePath];
}

final class AccountUiFeedbackConsumed extends AccountEvent {
  const AccountUiFeedbackConsumed();
}

final class AccountNoSession extends AccountEvent {
  const AccountNoSession();
}
