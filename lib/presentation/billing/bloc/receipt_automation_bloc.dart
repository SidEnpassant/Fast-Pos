import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inventopos/application/messaging/build_message_use_cases.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';

// Events
sealed class ReceiptAutomationEvent extends Equatable {
  const ReceiptAutomationEvent();
  @override
  List<Object?> get props => [];
}

class ReceiptAutomationSubmitted extends ReceiptAutomationEvent {
  const ReceiptAutomationSubmitted({
    required this.bill,
    required this.shopName,
    required this.prefs,
  });
  final Bill bill;
  final String shopName;
  final AiPreferences prefs;

  @override
  List<Object?> get props => [bill, shopName, prefs];
}

// State
class ReceiptAutomationState extends Equatable {
  const ReceiptAutomationState({this.receiptMessage, this.thankYouMessage});
  final OutboundMessage? receiptMessage;
  final OutboundMessage? thankYouMessage;

  @override
  List<Object?> get props => [receiptMessage, thankYouMessage];
}

// Bloc
class ReceiptAutomationBloc
    extends Bloc<ReceiptAutomationEvent, ReceiptAutomationState> {
  ReceiptAutomationBloc({
    required BuildReceiptMessageUseCase buildReceipt,
    required BuildPaymentThankYouMessageUseCase buildThankYou,
  })  : _buildReceipt = buildReceipt,
        _buildThankYou = buildThankYou,
        super(const ReceiptAutomationState()) {
    on<ReceiptAutomationSubmitted>((event, emit) {
      final receipt = _buildReceipt(
        bill: event.bill,
        shopName: event.shopName,
        prefs: event.prefs,
      );
      OutboundMessage? thankYou;
      if (event.bill.paidAmount >= event.bill.totalAmount &&
          event.prefs.paymentThankYouEnabled) {
        thankYou = _buildThankYou(
          bill: event.bill,
          shopName: event.shopName,
          prefs: event.prefs,
        );
      }
      emit(ReceiptAutomationState(
        receiptMessage: receipt,
        thankYouMessage: thankYou,
      ));
    });
  }

  final BuildReceiptMessageUseCase _buildReceipt;
  final BuildPaymentThankYouMessageUseCase _buildThankYou;
}
