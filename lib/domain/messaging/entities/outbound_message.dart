import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/messaging/entities/message_channel.dart';
import 'package:inventopos/domain/messaging/entities/message_template_id.dart';

class OutboundMessage extends Equatable {
  const OutboundMessage({
    required this.channel,
    required this.phone,
    required this.body,
    this.filePath,
    this.templateId,
    this.recipientName,
  });

  final MessageChannel channel;
  final String phone;
  final String body;
  final String? filePath;
  final MessageTemplateId? templateId;
  final String? recipientName;

  @override
  List<Object?> get props =>
      [channel, phone, body, filePath, templateId, recipientName];
}
