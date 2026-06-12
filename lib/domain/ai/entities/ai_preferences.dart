import 'package:equatable/equatable.dart';

class AiPreferences extends Equatable {
  const AiPreferences({
    required this.userId,
    this.enabled = false,
    this.enhancedContext = false,
    this.dailyBriefEnabled = true,
    this.reorderAlertsEnabled = true,
    this.partialBillRemindersEnabled = true,
    this.creditAlertsEnabled = true,
    this.deadStockAlertsEnabled = true,
    this.marginAlertsEnabled = true,
    this.billSanityCheckEnabled = true,
    this.eodSummaryEnabled = true,
    this.openingSnapshotEnabled = true,
    this.repeatOrderEnabled = true,
    this.autoReceiptShareEnabled = false,
    this.paymentThankYouEnabled = true,
    this.expenseAlertsEnabled = true,
    this.weeklyDigestEnabled = true,
    this.language = 'en',
    this.dailyTokenBudget = 50000,
    this.ownerWhatsAppPhone,
    this.supplierWhatsAppPhone,
    this.defaultMessageChannel = 'whatsapp',
    this.merchantUpiId,
  });

  final String userId;
  final bool enabled;
  final bool enhancedContext;
  final bool dailyBriefEnabled;
  final bool reorderAlertsEnabled;
  final bool partialBillRemindersEnabled;
  final bool creditAlertsEnabled;
  final bool deadStockAlertsEnabled;
  final bool marginAlertsEnabled;
  final bool billSanityCheckEnabled;
  final bool eodSummaryEnabled;
  final bool openingSnapshotEnabled;
  final bool repeatOrderEnabled;
  final bool autoReceiptShareEnabled;
  final bool paymentThankYouEnabled;
  final bool expenseAlertsEnabled;
  final bool weeklyDigestEnabled;
  final String language;
  final int dailyTokenBudget;
  final String? ownerWhatsAppPhone;
  final String? supplierWhatsAppPhone;
  final String defaultMessageChannel;
  final String? merchantUpiId;

  AiPreferences copyWith({
    bool? enabled,
    bool? enhancedContext,
    bool? dailyBriefEnabled,
    bool? reorderAlertsEnabled,
    bool? partialBillRemindersEnabled,
    bool? creditAlertsEnabled,
    bool? deadStockAlertsEnabled,
    bool? marginAlertsEnabled,
    bool? billSanityCheckEnabled,
    bool? eodSummaryEnabled,
    bool? openingSnapshotEnabled,
    bool? repeatOrderEnabled,
    bool? autoReceiptShareEnabled,
    bool? paymentThankYouEnabled,
    bool? expenseAlertsEnabled,
    bool? weeklyDigestEnabled,
    String? language,
    int? dailyTokenBudget,
    String? ownerWhatsAppPhone,
    String? supplierWhatsAppPhone,
    String? defaultMessageChannel,
    String? merchantUpiId,
  }) =>
      AiPreferences(
        userId: userId,
        enabled: enabled ?? this.enabled,
        enhancedContext: enhancedContext ?? this.enhancedContext,
        dailyBriefEnabled: dailyBriefEnabled ?? this.dailyBriefEnabled,
        reorderAlertsEnabled: reorderAlertsEnabled ?? this.reorderAlertsEnabled,
        partialBillRemindersEnabled:
            partialBillRemindersEnabled ?? this.partialBillRemindersEnabled,
        creditAlertsEnabled: creditAlertsEnabled ?? this.creditAlertsEnabled,
        deadStockAlertsEnabled:
            deadStockAlertsEnabled ?? this.deadStockAlertsEnabled,
        marginAlertsEnabled: marginAlertsEnabled ?? this.marginAlertsEnabled,
        billSanityCheckEnabled:
            billSanityCheckEnabled ?? this.billSanityCheckEnabled,
        eodSummaryEnabled: eodSummaryEnabled ?? this.eodSummaryEnabled,
        openingSnapshotEnabled:
            openingSnapshotEnabled ?? this.openingSnapshotEnabled,
        repeatOrderEnabled: repeatOrderEnabled ?? this.repeatOrderEnabled,
        autoReceiptShareEnabled:
            autoReceiptShareEnabled ?? this.autoReceiptShareEnabled,
        paymentThankYouEnabled:
            paymentThankYouEnabled ?? this.paymentThankYouEnabled,
        expenseAlertsEnabled: expenseAlertsEnabled ?? this.expenseAlertsEnabled,
        weeklyDigestEnabled: weeklyDigestEnabled ?? this.weeklyDigestEnabled,
        language: language ?? this.language,
        dailyTokenBudget: dailyTokenBudget ?? this.dailyTokenBudget,
        ownerWhatsAppPhone: ownerWhatsAppPhone ?? this.ownerWhatsAppPhone,
        supplierWhatsAppPhone:
            supplierWhatsAppPhone ?? this.supplierWhatsAppPhone,
        defaultMessageChannel:
            defaultMessageChannel ?? this.defaultMessageChannel,
        merchantUpiId: merchantUpiId ?? this.merchantUpiId,
      );

  @override
  List<Object?> get props => [
        userId,
        enabled,
        enhancedContext,
        dailyBriefEnabled,
        reorderAlertsEnabled,
        partialBillRemindersEnabled,
        creditAlertsEnabled,
        deadStockAlertsEnabled,
        marginAlertsEnabled,
        billSanityCheckEnabled,
        eodSummaryEnabled,
        openingSnapshotEnabled,
        repeatOrderEnabled,
        autoReceiptShareEnabled,
        paymentThankYouEnabled,
        expenseAlertsEnabled,
        weeklyDigestEnabled,
        language,
        dailyTokenBudget,
        ownerWhatsAppPhone,
        supplierWhatsAppPhone,
        defaultMessageChannel,
        merchantUpiId,
      ];
}
