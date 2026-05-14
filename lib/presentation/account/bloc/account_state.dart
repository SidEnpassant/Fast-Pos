import 'package:equatable/equatable.dart';

class AccountState extends Equatable {
  const AccountState({
    this.fields = const {},
    this.loading = true,
  });

  final Map<String, dynamic> fields;
  final bool loading;

  AccountState copyWith({
    Map<String, dynamic>? fields,
    bool? loading,
  }) {
    return AccountState(
      fields: fields ?? this.fields,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [fields, loading];
}
