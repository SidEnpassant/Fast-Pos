import 'package:equatable/equatable.dart';

class AiInsight extends Equatable {
  const AiInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.dedupKey,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String dedupKey;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  @override
  List<Object?> get props => [id, type, title, body, dedupKey, readAt, createdAt];
}
