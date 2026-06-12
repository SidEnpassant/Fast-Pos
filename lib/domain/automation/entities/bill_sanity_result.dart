import 'package:equatable/equatable.dart';

class BillSanityResult extends Equatable {
  const BillSanityResult({
    this.warnings = const [],
    this.blocked = false,
  });

  final List<String> warnings;
  final bool blocked;

  bool get hasWarnings => warnings.isNotEmpty;

  String get message => warnings.join('\n');

  @override
  List<Object?> get props => [warnings, blocked];
}
