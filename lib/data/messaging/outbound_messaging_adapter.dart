import 'package:inventopos/domain/automation/failures/automation_failure.dart';
import 'package:inventopos/domain/messaging/entities/message_channel.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';
import 'package:inventopos/domain/messaging/repositories/outbound_messaging_port.dart';
import 'package:inventopos/domain/messaging/services/phone_normalizer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherOutboundAdapter implements OutboundMessagingPort {
  @override
  Future<MessagingResult> launch(OutboundMessage message) async {
    try {
      final uri = _uriFor(message);
      if (uri == null) {
        return (failure: const AutomationInvalidPhone());
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        return (failure: const AutomationLaunchFailed('Could not open messaging app'));
      }
      return (failure: null);
    } catch (e) {
      return (failure: AutomationLaunchFailed('$e'));
    }
  }

  Uri? _uriFor(OutboundMessage message) {
    return switch (message.channel) {
      MessageChannel.whatsapp => _whatsapp(message),
      MessageChannel.sms => _sms(message),
      MessageChannel.phoneCall => _tel(message),
      MessageChannel.shareText => null,
      MessageChannel.shareFile => null,
    };
  }

  Uri? _whatsapp(OutboundMessage m) {
    final phone = PhoneNormalizer.forWhatsApp(m.phone);
    if (phone == null) return null;
    return Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(m.body)}',
    );
  }

  Uri? _sms(OutboundMessage m) {
    final phone = PhoneNormalizer.forSms(m.phone);
    if (phone == null) return null;
    return Uri.parse('sms:$phone?body=${Uri.encodeComponent(m.body)}');
  }

  Uri? _tel(OutboundMessage m) {
    final phone = PhoneNormalizer.forSms(m.phone);
    if (phone == null) return null;
    return Uri.parse('tel:$phone');
  }
}

class SharePlusOutboundAdapter implements OutboundMessagingPort {
  @override
  Future<MessagingResult> launch(OutboundMessage message) async {
    try {
      if (message.channel == MessageChannel.shareFile &&
          message.filePath != null) {
        await Share.shareXFiles([XFile(message.filePath!)], text: message.body);
      } else {
        await Share.share(message.body);
      }
      return (failure: null);
    } catch (e) {
      return (failure: AutomationLaunchFailed('$e'));
    }
  }
}

/// Routes to url_launcher or share_plus based on channel.
class CompositeOutboundMessagingAdapter implements OutboundMessagingPort {
  CompositeOutboundMessagingAdapter({
    UrlLauncherOutboundAdapter? urlLauncher,
    SharePlusOutboundAdapter? sharePlus,
  })  : _url = urlLauncher ?? UrlLauncherOutboundAdapter(),
        _share = sharePlus ?? SharePlusOutboundAdapter();

  final UrlLauncherOutboundAdapter _url;
  final SharePlusOutboundAdapter _share;

  @override
  Future<MessagingResult> launch(OutboundMessage message) {
    if (message.channel == MessageChannel.shareText ||
        message.channel == MessageChannel.shareFile) {
      return _share.launch(message);
    }
    return _url.launch(message);
  }
}
