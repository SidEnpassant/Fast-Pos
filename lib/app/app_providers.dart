import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/app/local_notifications_holder.dart';
import 'package:inventopos/application/ai/build_briefing_metrics_use_case.dart';
import 'package:inventopos/application/ai/observe_ai_insights_use_case.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/ai/replay_offline_ai_queue_use_case.dart';
import 'package:inventopos/application/ai/run_daily_business_brief_use_case.dart';
import 'package:inventopos/application/ai/save_ai_preferences_use_case.dart';
import 'package:inventopos/application/auth/request_password_reset_use_case.dart';
import 'package:inventopos/application/auth/sign_in_use_case.dart';
import 'package:inventopos/application/auth/sign_out_use_case.dart';
import 'package:inventopos/application/auth/verify_recovery_otp_use_case.dart';
import 'package:inventopos/application/auth/update_password_use_case.dart';
import 'package:inventopos/application/automation/automation_use_cases.dart';
import 'package:inventopos/application/automation/sync_automation_jobs_from_prefs_use_case.dart';
import 'package:inventopos/application/billing/delete_bill_use_case.dart';
import 'package:inventopos/application/billing/download_bill_pdf_use_case.dart';
import 'package:inventopos/application/billing/download_remote_pdf_to_device_use_case.dart';
import 'package:inventopos/application/billing/extract_text_lines_from_image_path_use_case.dart';
import 'package:inventopos/application/billing/lookup_product_name_by_barcode_use_case.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/billing/print_receipt_use_case.dart';
import 'package:inventopos/application/billing/regenerate_and_upload_bill_pdf_use_case.dart';
import 'package:inventopos/application/billing/replace_signed_bill_use_case.dart';
import 'package:inventopos/application/billing/resolve_product_for_barcode_use_case.dart';
import 'package:inventopos/application/billing/submit_bill_use_case.dart';
import 'package:inventopos/application/billing/sync_overdue_partial_bill_notifications_use_case.dart';
import 'package:inventopos/application/billing/update_bill_payment_use_case.dart';
import 'package:inventopos/application/billing/upload_bill_pdf_use_case.dart';
import 'package:inventopos/application/billing/validate_bill_draft_use_case.dart';
import 'package:inventopos/application/checkout/compute_checkout_totals_use_case.dart';
import 'package:inventopos/application/customers/upsert_customer_from_bill_use_case.dart';
import 'package:inventopos/application/daybook/compute_day_book_use_case.dart';
import 'package:inventopos/application/daybook/record_cash_entry_use_case.dart';
import 'package:inventopos/application/inventory/decrement_stock_on_bill_use_case.dart';
import 'package:inventopos/application/inventory/evaluate_reorder_alerts_use_case.dart';
import 'package:inventopos/application/inventory/update_product_velocity_use_case.dart';
import 'package:inventopos/application/loyalty/earn_loyalty_points_use_case.dart';
import 'package:inventopos/application/loyalty/redeem_loyalty_points_use_case.dart';
import 'package:inventopos/application/messaging/build_message_use_cases.dart';
import 'package:inventopos/application/messaging/list_pending_message_actions_use_case.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/application/profile/patch_account_profile_field_use_case.dart';
import 'package:inventopos/application/profile/replace_account_signature_use_case.dart';
import 'package:inventopos/application/registration/register_account_use_case.dart';
import 'package:inventopos/application/returns/generate_credit_note_pdf_use_case.dart';
import 'package:inventopos/application/returns/process_return_use_case.dart';
import 'package:inventopos/application/security/authenticate_user_use_case.dart';
import 'package:inventopos/application/stock_audit/complete_stock_audit_use_case.dart';
import 'package:inventopos/application/stock_audit/start_stock_audit_use_case.dart';
import 'package:inventopos/application/tax/compute_gst_for_bill_use_case.dart';
import 'package:inventopos/core/notifications/local_notification_service.dart';
import 'package:inventopos/core/notifications/notification_sync_coordinator.dart';
import 'package:inventopos/data/ai/ai_insights_repository_impl.dart';
import 'package:inventopos/data/ai/ai_preferences_repository_impl.dart';
import 'package:inventopos/data/ai/ai_request_queue.dart';
import 'package:inventopos/data/ai/ai_telemetry.dart';
import 'package:inventopos/data/ai/edge_function_client.dart';
import 'package:inventopos/data/ai/supabase_ai_gateway_impl.dart';
import 'package:inventopos/data/automation/automation_job_repository_impl.dart';
import 'package:inventopos/data/billing/barcode_product_lookup_repository_impl.dart';
import 'package:inventopos/data/billing/bill_pdf_generator.dart';
import 'package:inventopos/data/export/export_repository_impl.dart';
import 'package:inventopos/data/files/remote_pdf_download_repository_impl.dart';
import 'package:inventopos/data/hardware/esc_pos_printer_repository_impl.dart';
import 'package:inventopos/data/inventory/product_repository_impl.dart';
import 'package:inventopos/data/messaging/outbound_messaging_adapter.dart';
import 'package:inventopos/data/repositories/auth_repository_impl.dart';
import 'package:inventopos/data/repositories/cash_register_repository_impl.dart';
import 'package:inventopos/data/repositories/credit_note_repository_impl.dart';
import 'package:inventopos/data/repositories/customer_repository_impl.dart';
import 'package:inventopos/data/repositories/expense_repository_impl.dart';
import 'package:inventopos/data/repositories/loyalty_repository_impl.dart';
import 'package:inventopos/data/repositories/notifications_repository_impl.dart';
import 'package:inventopos/data/repositories/offline_first_bills_repository.dart';
import 'package:inventopos/data/repositories/profile_repository_impl.dart';
import 'package:inventopos/data/repositories/purchase_order_repository_impl.dart';
import 'package:inventopos/data/repositories/registration_repository_impl.dart';
import 'package:inventopos/data/repositories/stock_audit_repository_impl.dart';
import 'package:inventopos/data/repositories/supplier_repository_impl.dart';
import 'package:inventopos/data/repositories/transactions_repository_impl.dart';
import 'package:inventopos/data/returns/credit_note_pdf_generator.dart';
import 'package:inventopos/data/sync/sync_coordinator.dart';
import 'package:inventopos/data/sync/sync_repository_impl.dart';
import 'package:inventopos/data/vision/text_recognition_repository_impl.dart';
import 'package:inventopos/domain/ai/repositories/ai_gateway_port.dart';
import 'package:inventopos/domain/ai/repositories/ai_insights_port.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';
import 'package:inventopos/domain/automation/repositories/automation_job_port.dart';
import 'package:inventopos/domain/messaging/repositories/outbound_messaging_port.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/barcode_product_lookup_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/cash_register_repository.dart';
import 'package:inventopos/domain/repositories/credit_note_repository.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/domain/repositories/loyalty_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/printer_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/purchase_order_repository.dart';
import 'package:inventopos/domain/repositories/registration_repository.dart';
import 'package:inventopos/domain/repositories/remote_pdf_download_repository.dart';
import 'package:inventopos/domain/repositories/stock_audit_repository.dart';
import 'package:inventopos/domain/repositories/supplier_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:inventopos/domain/repositories/text_recognition_repository.dart';
import 'package:inventopos/domain/repositories/transactions_repository.dart';

/// Single composition root for repositories and application use cases.
List<RepositoryProvider<dynamic>> appRepositoryProviders() {
  return [
    RepositoryProvider<CashRegisterRepository>(
      create: (_) => CashRegisterRepositoryImpl(),
    ),
    RepositoryProvider<LoyaltyRepository>(
      create: (_) => LoyaltyRepositoryImpl(),
    ),
    RepositoryProvider<StockAuditRepository>(
      create: (_) => StockAuditRepositoryImpl(),
    ),
    RepositoryProvider<RecordCashEntryUseCase>(
      create: (c) => RecordCashEntryUseCase(c.read<CashRegisterRepository>()),
    ),
    RepositoryProvider<ComputeDayBookUseCase>(
      create: (c) => ComputeDayBookUseCase(c.read<CashRegisterRepository>()),
    ),

    RepositoryProvider<SupplierRepository>(
      create: (_) => SupplierRepositoryImpl(),
    ),
    RepositoryProvider<PurchaseOrderRepository>(
      create: (_) => PurchaseOrderRepositoryImpl(),
    ),
    RepositoryProvider<CreditNoteRepository>(
      create: (_) => CreditNoteRepositoryImpl(),
    ),
    RepositoryProvider<CreditNotePdfGenerator>(
      create: (_) => CreditNotePdfGenerator(),
    ),
    RepositoryProvider<GenerateCreditNotePdfUseCase>(
      create: (c) => GenerateCreditNotePdfUseCase(
        c.read<ProfileRepository>(),
        c.read<CreditNotePdfGenerator>(),
      ),
    ),
    RepositoryProvider<ProcessReturnUseCase>(
      create: (c) => ProcessReturnUseCase(
        c.read<CreditNoteRepository>(),
      ),
    ),
    RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(),
    ),
    RepositoryProvider<RegistrationRepository>(
      create: (_) => RegistrationRepositoryImpl(),
    ),
    RepositoryProvider<SyncRepository>(
      create: (_) => SyncRepositoryImpl(),
    ),
    RepositoryProvider<BillsRepository>(
      create: (c) =>
          OfflineFirstBillsRepository(sync: c.read<SyncRepository>()),
    ),
    RepositoryProvider<ProductRepository>(
      create: (_) => ProductRepositoryImpl(),
    ),
    RepositoryProvider<ExpenseRepository>(
      create: (_) => ExpenseRepositoryImpl(),
    ),
    RepositoryProvider<CustomerRepository>(
      create: (_) => CustomerRepositoryImpl(),
    ),
    RepositoryProvider<PrinterRepository>(
      create: (_) => EscPosPrinterRepositoryImpl(),
    ),
    RepositoryProvider<ExportRepositoryImpl>(
      create: (_) => ExportRepositoryImpl(),
    ),
    RepositoryProvider<ProfileRepository>(
      create: (_) => ProfileRepositoryImpl(),
    ),
    RepositoryProvider<LocalNotificationService>.value(
      value: appLocalNotifications,
    ),
    RepositoryProvider<NotificationsRepository>(
      create: (_) => NotificationsRepositoryImpl(),
    ),
    RepositoryProvider<NotificationSyncCoordinator>(
      create: (c) => NotificationSyncCoordinator(
        c.read<NotificationsRepository>(),
        c.read<LocalNotificationService>(),
      ),
    ),
    RepositoryProvider<TransactionsRepository>(
      create: (_) => TransactionsRepositoryImpl(),
    ),
    RepositoryProvider<BarcodeProductLookupRepository>(
      create: (_) => BarcodeProductLookupRepositoryImpl(),
    ),
    RepositoryProvider<TextRecognitionRepository>(
      create: (_) => TextRecognitionRepositoryImpl(),
    ),
    RepositoryProvider<RemotePdfDownloadRepository>(
      create: (_) => RemotePdfDownloadRepositoryImpl(),
    ),
    RepositoryProvider<LookupProductNameByBarcodeUseCase>(
      create: (c) => LookupProductNameByBarcodeUseCase(
        c.read<ProductRepository>(),
        c.read<BarcodeProductLookupRepository>(),
      ),
    ),
    RepositoryProvider<ExtractTextLinesFromImagePathUseCase>(
      create: (c) => ExtractTextLinesFromImagePathUseCase(
        c.read<TextRecognitionRepository>(),
      ),
    ),
    RepositoryProvider<DownloadRemotePdfToDeviceUseCase>(
      create: (c) => DownloadRemotePdfToDeviceUseCase(
        c.read<RemotePdfDownloadRepository>(),
      ),
    ),
    RepositoryProvider<DownloadBillPdfUseCase>(
      create: (_) => DownloadBillPdfUseCase(),
    ),
    RepositoryProvider<ObserveBillsUseCase>(
      create: (c) => ObserveBillsUseCase(c.read<BillsRepository>()),
    ),
    RepositoryProvider<ObserveProfileForCurrentUserUseCase>(
      create: (c) =>
          ObserveProfileForCurrentUserUseCase(c.read<ProfileRepository>()),
    ),
    RepositoryProvider<BillPdfGenerator>(
      create: (_) => BillPdfGenerator(),
    ),
    RepositoryProvider<ComputeCheckoutTotalsUseCase>(
      create: (_) => ComputeCheckoutTotalsUseCase(),
    ),
    RepositoryProvider<AuthenticateUserUseCase>(
      create: (_) => AuthenticateUserUseCase(),
    ),
    RepositoryProvider<UpsertCustomerFromBillUseCase>(
      create: (c) =>
          UpsertCustomerFromBillUseCase(c.read<CustomerRepository>()),
    ),
    RepositoryProvider<ResolveProductForBarcodeUseCase>(
      create: (c) =>
          ResolveProductForBarcodeUseCase(c.read<ProductRepository>()),
    ),
    RepositoryProvider<PrintReceiptUseCase>(
      create: (c) => PrintReceiptUseCase(c.read<PrinterRepository>()),
    ),
    RepositoryProvider<ValidateBillDraftUseCase>(
      create: (c) => ValidateBillDraftUseCase(c.read<ProductRepository>()),
    ),
    RepositoryProvider<DecrementStockOnBillUseCase>(
      create: (c) => DecrementStockOnBillUseCase(
        c.read<ProductRepository>(),
        c.read<SyncRepository>(),
      ),
    ),
    RepositoryProvider<UploadBillPdfUseCase>(
      create: (c) => UploadBillPdfUseCase(c.read<BillsRepository>()),
    ),
    RepositoryProvider<RegenerateAndUploadBillPdfUseCase>(
      create: (c) => RegenerateAndUploadBillPdfUseCase(
        c.read<BillsRepository>(),
        c.read<ProfileRepository>(),
        c.read<BillPdfGenerator>(),
        c.read<UploadBillPdfUseCase>(),
      ),
    ),
    RepositoryProvider<SignInUseCase>(
      create: (c) => SignInUseCase(c.read<AuthRepository>()),
    ),
    RepositoryProvider<SignOutUseCase>(
      create: (c) => SignOutUseCase(c.read<AuthRepository>()),
    ),
    RepositoryProvider<RequestPasswordResetUseCase>(
      create: (c) => RequestPasswordResetUseCase(c.read<AuthRepository>()),
    ),
    RepositoryProvider<VerifyRecoveryOtpUseCase>(
      create: (c) => VerifyRecoveryOtpUseCase(c.read<AuthRepository>()),
    ),
    RepositoryProvider<UpdatePasswordUseCase>(
      create: (c) => UpdatePasswordUseCase(c.read<AuthRepository>()),
    ),
    RepositoryProvider<RegisterAccountUseCase>(
      create: (c) => RegisterAccountUseCase(c.read<RegistrationRepository>()),
    ),
    RepositoryProvider<ReplaceSignedBillUseCase>(
      create: (c) => ReplaceSignedBillUseCase(c.read<BillsRepository>()),
    ),
    RepositoryProvider<DeleteBillUseCase>(
      create: (c) => DeleteBillUseCase(c.read<BillsRepository>()),
    ),
    RepositoryProvider<UpdateBillPaymentUseCase>(
      create: (c) => UpdateBillPaymentUseCase(
        c.read<BillsRepository>(),
        c.read<RegenerateAndUploadBillPdfUseCase>(),
      ),
    ),
    RepositoryProvider<SyncOverduePartialBillNotificationsUseCase>(
      create: (c) => SyncOverduePartialBillNotificationsUseCase(
        c.read<BillsRepository>(),
      ),
    ),
    RepositoryProvider<PatchAccountProfileFieldUseCase>(
      create: (c) =>
          PatchAccountProfileFieldUseCase(c.read<ProfileRepository>()),
    ),
    RepositoryProvider<ReplaceAccountSignatureUseCase>(
      create: (c) =>
          ReplaceAccountSignatureUseCase(c.read<ProfileRepository>()),
    ),
    RepositoryProvider<SyncCoordinator>(
      create: (c) => SyncCoordinator(c.read<SyncRepository>()),
    ),
    RepositoryProvider<EdgeFunctionClient>(
      create: (_) => EdgeFunctionClient(),
    ),
    RepositoryProvider<AiGatewayPort>(
      create: (c) => SupabaseAiGatewayImpl(c.read<EdgeFunctionClient>()),
    ),
    RepositoryProvider<AiPreferencesPort>(
      create: (_) => AiPreferencesRepositoryImpl(),
    ),
    RepositoryProvider<AiInsightsPort>(
      create: (_) => AiInsightsRepositoryImpl(),
    ),
    RepositoryProvider<AutomationJobPort>(
      create: (_) => AutomationJobRepositoryImpl(),
    ),
    RepositoryProvider<AiRequestQueue>(
      create: (_) => AiRequestQueue(),
    ),
    RepositoryProvider<AiTelemetry>(
      create: (_) => AiTelemetry(),
    ),
    RepositoryProvider<RunDailyBusinessBriefUseCase>(
      create: (c) => RunDailyBusinessBriefUseCase(
        c.read<AiGatewayPort>(),
        c.read<AiPreferencesPort>(),
      ),
    ),
    RepositoryProvider<SyncAutomationJobsFromPrefsUseCase>(
      create: (c) => SyncAutomationJobsFromPrefsUseCase(
        c.read<AutomationJobPort>(),
      ),
    ),
    RepositoryProvider<OutboundMessagingPort>(
      create: (_) => CompositeOutboundMessagingAdapter(),
    ),
    RepositoryProvider<LaunchOutboundMessageUseCase>(
      create: (c) => LaunchOutboundMessageUseCase(
        c.read<OutboundMessagingPort>(),
      ),
    ),
    RepositoryProvider<BuildPartialPaymentMessageUseCase>(
      create: (_) => BuildPartialPaymentMessageUseCase(),
    ),
    RepositoryProvider<BuildPaymentThankYouMessageUseCase>(
      create: (_) => BuildPaymentThankYouMessageUseCase(),
    ),
    RepositoryProvider<BuildReceiptMessageUseCase>(
      create: (_) => BuildReceiptMessageUseCase(),
    ),
    RepositoryProvider<BuildEodSummaryMessageUseCase>(
      create: (_) => BuildEodSummaryMessageUseCase(),
    ),
    RepositoryProvider<BuildRepeatOrderTemplateUseCase>(
      create: (_) => BuildRepeatOrderTemplateUseCase(),
    ),
    RepositoryProvider<ListPendingMessageActionsUseCase>(
      create: (c) => ListPendingMessageActionsUseCase(
        buildPartial: c.read<BuildPartialPaymentMessageUseCase>(),
        buildEod: c.read<BuildEodSummaryMessageUseCase>(),
      ),
    ),
    RepositoryProvider<ListAutomationJobsUseCase>(
      create: (c) => ListAutomationJobsUseCase(c.read<AutomationJobPort>()),
    ),
    RepositoryProvider<ToggleAutomationJobUseCase>(
      create: (c) => ToggleAutomationJobUseCase(c.read<AutomationJobPort>()),
    ),
    RepositoryProvider<EvaluateCreditExposureUseCase>(
      create: (_) => EvaluateCreditExposureUseCase(),
    ),
    RepositoryProvider<BuildOpeningSnapshotUseCase>(
      create: (_) => BuildOpeningSnapshotUseCase(),
    ),
    RepositoryProvider<BuildEodSummaryUseCase>(
      create: (_) => BuildEodSummaryUseCase(),
    ),
    RepositoryProvider<EvaluateExpenseSpikeUseCase>(
      create: (_) => EvaluateExpenseSpikeUseCase(),
    ),
    RepositoryProvider<EvaluateDeadStockUseCase>(
      create: (c) => EvaluateDeadStockUseCase(c.read<ProductRepository>()),
    ),
    RepositoryProvider<EvaluateMarginLeaksUseCase>(
      create: (c) => EvaluateMarginLeaksUseCase(c.read<ProductRepository>()),
    ),
    RepositoryProvider<EvaluateBillSanityUseCase>(
      create: (_) => EvaluateBillSanityUseCase(),
    ),
    RepositoryProvider<SaveAiPreferencesUseCase>(
      create: (c) => SaveAiPreferencesUseCase(
        c.read<AiPreferencesPort>(),
        c.read<SyncAutomationJobsFromPrefsUseCase>(),
      ),
    ),
    RepositoryProvider<ObserveAiPreferencesUseCase>(
      create: (c) => ObserveAiPreferencesUseCase(c.read<AiPreferencesPort>()),
    ),
    RepositoryProvider<ObserveAiInsightsUseCase>(
      create: (c) => ObserveAiInsightsUseCase(c.read<AiInsightsPort>()),
    ),
    RepositoryProvider<BuildBriefingMetricsUseCase>(
      create: (_) => BuildBriefingMetricsUseCase(),
    ),
    RepositoryProvider<ReplayOfflineAiQueueUseCase>(
      create: (c) => ReplayOfflineAiQueueUseCase(
        c.read<AiRequestQueue>(),
        c.read<EdgeFunctionClient>(),
      ),
    ),
    RepositoryProvider<UpdateProductVelocityUseCase>(
      create: (c) => UpdateProductVelocityUseCase(c.read<ProductRepository>()),
    ),
    RepositoryProvider<EvaluateReorderAlertsUseCase>(
      create: (c) => EvaluateReorderAlertsUseCase(c.read<ProductRepository>()),
    ),
    RepositoryProvider<ComputeGstForBillUseCase>(
      create: (_) => const ComputeGstForBillUseCase(),
    ),
    RepositoryProvider<EarnLoyaltyPointsUseCase>(
      create: (c) => EarnLoyaltyPointsUseCase(
        c.read<LoyaltyRepository>(),
        c.read<CustomerRepository>(),
      ),
    ),
    RepositoryProvider<RedeemLoyaltyPointsUseCase>(
      create: (c) => RedeemLoyaltyPointsUseCase(
        c.read<LoyaltyRepository>(),
        c.read<CustomerRepository>(),
      ),
    ),
    RepositoryProvider<SubmitBillUseCase>(
      create: (c) => SubmitBillUseCase(
        c.read<BillsRepository>(),
        c.read<ProfileRepository>(),
        c.read<TransactionsRepository>(),
        c.read<BillPdfGenerator>(),
        c.read<AuthRepository>(),
        c.read<UpsertCustomerFromBillUseCase>(),
        c.read<ValidateBillDraftUseCase>(),
        c.read<DecrementStockOnBillUseCase>(),
        c.read<UploadBillPdfUseCase>(),
        c.read<UpdateProductVelocityUseCase>(),
        c.read<ComputeGstForBillUseCase>(),
        c.read<RecordCashEntryUseCase>(),
        c.read<EarnLoyaltyPointsUseCase>(),
        c.read<RedeemLoyaltyPointsUseCase>(),
      ),
    ),
    RepositoryProvider<StartStockAuditUseCase>(
      create: (c) => StartStockAuditUseCase(
        c.read<ProductRepository>(),
        c.read<StockAuditRepository>(),
      ),
    ),
    RepositoryProvider<CompleteStockAuditUseCase>(
      create: (c) => CompleteStockAuditUseCase(
        c.read<StockAuditRepository>(),
      ),
    ),
  ];
}
