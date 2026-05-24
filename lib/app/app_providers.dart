import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/app/local_notifications_holder.dart';
import 'package:inventopos/core/notifications/local_notification_service.dart';
import 'package:inventopos/core/notifications/notification_sync_coordinator.dart';
import 'package:inventopos/application/auth/request_password_reset_use_case.dart';
import 'package:inventopos/application/auth/sign_in_use_case.dart';
import 'package:inventopos/application/auth/sign_out_use_case.dart';
import 'package:inventopos/application/billing/delete_bill_use_case.dart';
import 'package:inventopos/application/billing/download_remote_pdf_to_device_use_case.dart';
import 'package:inventopos/application/billing/extract_text_lines_from_image_path_use_case.dart';
import 'package:inventopos/application/billing/lookup_product_name_by_barcode_use_case.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/billing/replace_signed_bill_use_case.dart';
import 'package:inventopos/application/billing/print_receipt_use_case.dart';
import 'package:inventopos/application/billing/resolve_product_for_barcode_use_case.dart';
import 'package:inventopos/application/billing/submit_bill_use_case.dart';
import 'package:inventopos/application/customers/upsert_customer_from_bill_use_case.dart';
import 'package:inventopos/application/billing/sync_overdue_partial_bill_notifications_use_case.dart';
import 'package:inventopos/application/billing/update_bill_payment_use_case.dart';
import 'package:inventopos/application/checkout/compute_checkout_totals_use_case.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/application/profile/patch_account_profile_field_use_case.dart';
import 'package:inventopos/application/profile/replace_account_signature_use_case.dart';
import 'package:inventopos/application/registration/register_account_use_case.dart';
import 'package:inventopos/application/security/authenticate_user_use_case.dart';
import 'package:inventopos/data/billing/barcode_product_lookup_repository_impl.dart';
import 'package:inventopos/data/billing/bill_pdf_generator.dart';
import 'package:inventopos/data/export/export_repository_impl.dart';
import 'package:inventopos/data/files/remote_pdf_download_repository_impl.dart';
import 'package:inventopos/data/hardware/esc_pos_printer_repository_impl.dart';
import 'package:inventopos/data/inventory/product_repository_impl.dart';
import 'package:inventopos/data/repositories/auth_repository_impl.dart';
import 'package:inventopos/data/repositories/customer_repository_impl.dart';
import 'package:inventopos/data/repositories/expense_repository_impl.dart';
import 'package:inventopos/data/repositories/notifications_repository_impl.dart';
import 'package:inventopos/data/repositories/offline_first_bills_repository.dart';
import 'package:inventopos/data/repositories/profile_repository_impl.dart';
import 'package:inventopos/data/repositories/registration_repository_impl.dart';
import 'package:inventopos/data/repositories/transactions_repository_impl.dart';
import 'package:inventopos/data/sync/sync_coordinator.dart';
import 'package:inventopos/data/sync/sync_repository_impl.dart';
import 'package:inventopos/data/vision/text_recognition_repository_impl.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/barcode_product_lookup_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/printer_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/registration_repository.dart';
import 'package:inventopos/domain/repositories/remote_pdf_download_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:inventopos/domain/repositories/text_recognition_repository.dart';
import 'package:inventopos/domain/repositories/transactions_repository.dart';
/// Single composition root for repositories and application use cases.
List<RepositoryProvider<dynamic>> appRepositoryProviders() {
  return [
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
      create: (c) => OfflineFirstBillsRepository(sync: c.read<SyncRepository>()),
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
      create: (c) => NotificationsRepositoryImpl(
        localNotifications: c.read<LocalNotificationService>(),
      ),
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
      create: (c) => UpsertCustomerFromBillUseCase(c.read<CustomerRepository>()),
    ),
    RepositoryProvider<ResolveProductForBarcodeUseCase>(
      create: (c) =>
          ResolveProductForBarcodeUseCase(c.read<ProductRepository>()),
    ),
    RepositoryProvider<PrintReceiptUseCase>(
      create: (c) => PrintReceiptUseCase(c.read<PrinterRepository>()),
    ),
    RepositoryProvider<SubmitBillUseCase>(
      create: (c) => SubmitBillUseCase(
        c.read<BillsRepository>(),
        c.read<ProfileRepository>(),
        c.read<TransactionsRepository>(),
        c.read<BillPdfGenerator>(),
        c.read<AuthRepository>(),
        c.read<UpsertCustomerFromBillUseCase>(),
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
      create: (c) => UpdateBillPaymentUseCase(c.read<BillsRepository>()),
    ),
    RepositoryProvider<SyncOverduePartialBillNotificationsUseCase>(
      create: (c) => SyncOverduePartialBillNotificationsUseCase(
        c.read<BillsRepository>(),
        c.read<NotificationsRepository>(),
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
  ];
}
