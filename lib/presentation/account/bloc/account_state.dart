import 'package:equatable/equatable.dart';

class AccountState extends Equatable {
  const AccountState({
    this.fields = const {},
    this.loading = true,
    this.mutationBusy = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final Map<String, dynamic> fields;
  final bool loading;
  final bool mutationBusy;
  final String? feedbackMessage;
  final bool feedbackIsError;

  AccountState copyWith({
    Map<String, dynamic>? fields,
    bool? loading,
    bool? mutationBusy,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return AccountState(
      fields: fields ?? this.fields,
      loading: loading ?? this.loading,
      mutationBusy: mutationBusy ?? this.mutationBusy,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError:
          clearFeedback ? false : (feedbackIsError ?? this.feedbackIsError),
    );
  }

  @override
  List<Object?> get props => [
        fields,
        loading,
        mutationBusy,
        feedbackMessage,
        feedbackIsError,
      ];
}
