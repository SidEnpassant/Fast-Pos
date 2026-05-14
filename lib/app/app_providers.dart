import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/auth/request_password_reset_use_case.dart';
import 'package:inventopos/application/auth/sign_in_use_case.dart';
import 'package:inventopos/application/auth/sign_out_use_case.dart';
import 'package:inventopos/application/billing/delete_bill_use_case.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/billing/replace_signed_bill_use_case.dart';
import 'package:inventopos/application/billing/submit_bill_use_case.dart';
import 'package:inventopos/application/billing/sync_overdue_partial_bill_notifications_use_case.dart';
import 'package:inventopos/application/billing/update_bill_payment_use_case.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/application/profile/patch_account_profile_field_use_case.dart';
import 'package:inventopos/application/profile/replace_account_signature_use_case.dart';
import 'package:inventopos/application/registration/register_account_use_case.dart';
import 'package:inventopos/data/billing/bill_pdf_generator.dart';
import 'package:inventopos/data/repositories/auth_repository_impl.dart';
import 'package:inventopos/data/repositories/bills_repository_impl.dart';
import 'package:inventopos/data/repositories/notifications_repository_impl.dart';
import 'package:inventopos/data/repositories/profile_repository_impl.dart';
import 'package:inventopos/data/repositories/registration_repository_impl.dart';
import 'package:inventopos/data/repositories/transactions_repository_impl.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/registration_repository.dart';
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
    RepositoryProvider<BillsRepository>(
      create: (_) => BillsRepositoryImpl(),
    ),
    RepositoryProvider<ProfileRepository>(
      create: (_) => ProfileRepositoryImpl(),
    ),
    RepositoryProvider<NotificationsRepository>(
      create: (_) => NotificationsRepositoryImpl(),
    ),
    RepositoryProvider<TransactionsRepository>(
      create: (_) => TransactionsRepositoryImpl(),
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
    RepositoryProvider<SubmitBillUseCase>(
      create: (c) => SubmitBillUseCase(
        c.read<BillsRepository>(),
        c.read<ProfileRepository>(),
        c.read<TransactionsRepository>(),
        c.read<BillPdfGenerator>(),
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
  ];
}
