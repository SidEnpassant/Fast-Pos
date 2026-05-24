# Fast POS (InventoPOS)

**Fast POS** is a Flutter point-of-sale (POS) client aimed at small businesses: authentication, dashboard, bill generation with PDF output, transaction lists, analytics, notifications, and account management. The Dart package name is **`inventopos`** (see `pubspec.yaml`).

This document describes features, architecture, how to run and test the app, and where to configure secrets and third-party services.

---

## Table of contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Project structure](#project-structure)
5. [Technology stack](#technology-stack)
6. [Prerequisites](#prerequisites)
7. [Getting started](#getting-started)
8. [Configuration](#configuration)
9. [Running and building](#running-and-building)
10. [Testing](#testing)
11. [Routing](#routing)
12. [Presentation: blocs and screens](#presentation-blocs-and-screens)
13. [Domain and application layers](#domain-and-application-layers)
14. [Data layer and integrations](#data-layer-and-integrations)
15. [Billing flows (detailed)](#billing-flows-detailed)
16. [Code quality and analysis](#code-quality-and-analysis)
17. [Troubleshooting](#troubleshooting)
18. [Repository](#repository)

---

## Overview

- **Platform:** Flutter (Dart SDK **^3.5.1**), Material Design, Android and iOS (and other Flutter targets where supported).
- **Backend:** [Supabase](https://supabase.com/) via `supabase_flutter` (auth, Postgres-backed data, realtime where used in repositories).
- **Navigation:** [go_router](https://pub.dev/packages/go_router) with auth-aware redirects and a **StatefulShellRoute** tab shell for the main app.
- **State management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) / **Bloc** (event-driven state; **Cubit is not used** for these flows).
- **Structure:** Layered **Clean Architecture**-style layout (`domain`, `data`, `application`, `presentation`, `core`) with **repository abstractions** in the domain and **use cases** in the application layer.

---

## Features

### Authentication and registration

- Sign-in and sign-out wired through **`AuthRepository`** and **`AuthBloc`** (global session flow).
- Dedicated **`LoginBloc`** for login form validation and submission orchestration.
- Registration and post-registration flows (e.g. **`RegisterBloc`**, **`RegistrationSuccessBloc`**).
- Password reset entry point (**`ForgotPasswordBloc`** + **`RequestPasswordResetUseCase`**).

### Dashboard

- **`DashboardScreen`** with **`DashboardBloc`**: bill/transaction-oriented summaries (backed by **`ObserveBillsUseCase`** and profile access where needed).
- Header and layout widgets under `lib/presentation/dashboard/widgets/`.

### Billing

- **Draft lines:** **`BillDraftBloc`** (add/remove/clear lines, in-memory draft).
- **Submit bill:** **`BillSubmissionBloc`** + **`SubmitBillUseCase`** — persists bill and transaction data, generates PDF via **`BillPdfGenerator`**, returns a result with a local **PDF path**.
- **Customer voice input (main screen):** **`BillVoiceAssistBloc`** + `speech_to_text` for the customer name field.
- **Product assist:** Barcode scan bottom sheet (**`showBarcodeProductNameBottomSheet`**) using **`LookupProductNameByBarcodeUseCase`**; OCR line picker (**`showOcrLinePickerDialog`**) using **`ExtractTextLinesFromImagePathUseCase`**; **add product** dialog (**`showAddBillProductDialog`**) with optional speech for comments.
- **PDF after submit:** View/share helpers; optional sample remote PDF download via **`DownloadRemotePdfToDeviceUseCase`** and **`BillInvoiceDownloadDemo`**.

### Transactions

- **Complete** and **incomplete** transaction experiences with dedicated blocs (e.g. **`CompleteTransactionsBloc`**, **`IncompleteTransactionsBloc`**).
- **Signed bill actions:** **`TransactionBillActionsBloc`** (replace signed bill, delete, etc., coordinated with use cases such as **`ReplaceSignedBillUseCase`**, **`DeleteBillUseCase`** where applicable).
- Shared UI pieces (e.g. signed bill preview, feedback listeners, bill cards) under `lib/presentation/transactions/widgets/`.

### Analytics

- **`AnalyticsBloc`** + **`ObserveBillsUseCase`** for revenue-oriented UI.
- **`MonthlyRevenueAnalysis`** screen composed of smaller widgets (charts, tables, shimmer, app bar) under `lib/presentation/analytics/widgets/`.

### Notifications

- **`NotificationsBloc`** fed by **`NotificationsRepository`** and the current user id from auth.

### Account / profile

- **`AccountBloc`** coordinates profile observation, field patches, signature replacement, and auth/session edge cases via **`ObserveProfileForCurrentUserUseCase`**, **`PatchAccountProfileFieldUseCase`**, **`ReplaceAccountSignatureUseCase`**, and repositories.
- UI split into **`my_account.dart`** and widgets under `lib/presentation/account/widgets/`.

### Shell and navigation

- **`ShellPage`** hosts the bottom (or equivalent) navigation driven by **`StatefulShellRoute.indexedStack`** branches in **`app_router.dart`**.

---

## Architecture

### Layers (high level)

| Layer | Path | Responsibility |
|--------|------|------------------|
| **Domain** | `lib/domain/` | Entities, value objects, **repository interfaces** (contracts only). No Flutter UI, no Supabase imports. |
| **Application** | `lib/application/` | **Use cases** — single-purpose orchestration (call one or more repositories, enforce application rules). |
| **Data** | `lib/data/` | **Repository implementations**, Supabase/Dio/HTTP clients, mappers, PDF generation, barcode/OCR/download adapters. |
| **Presentation** | `lib/presentation/` | **Widgets, screens, Blocs**, `BlocListener` / `BlocBuilder` / `BlocConsumer`; depends on application use cases and domain types via DI. |
| **Core** | `lib/core/` | Router, theme, shared widgets, utilities, performance helpers. |
| **App** | `lib/app/` | **Composition root**: `bootstrap.dart`, `app_providers.dart`, `fast_pos_app.dart`. |

### Bloc (not Cubit)

Feature state is modeled with **`Bloc<Event, State>`** subclasses and **Equatable** (or equivalent) states where used. Events are explicit classes (e.g. **`BillVoiceAssistTogglePressed`**). This keeps transitions auditable and testable compared to ad hoc `setState` for business rules.

### MVVM (practical mapping in Flutter)

- **View:** Flutter widgets (`StatelessWidget` / `StatefulWidget`).
- **“View model” role:** Often fulfilled by **Bloc state** + small widget extractors; forms may still hold `TextEditingController`s where appropriate.
- **Model / use case:** Domain + application layers.

### SOLID (how the repo applies it)

- **SRP:** Use cases and repositories are split by concern; large screens are partially decomposed (billing assistants, account widgets, analytics widgets).
- **DIP:** UI and blocs depend on **abstractions** (`*Repository`, use cases) registered in **`appRepositoryProviders()`**, not on concrete Supabase types in the presentation layer for main flows.
- **OCP / LSP / ISP:** Favor small repository surfaces and replaceable implementations (e.g. barcode lookup, text recognition, remote PDF download behind interfaces).

---

## Project structure

Simplified map (see repo for full tree):

```text
lib/
  main.dart                 # Entry: initializeApp() then runApp(fastPosRoot())
  supabase_config.dart      # NOT in git — you must add (see Configuration)
  app/
    bootstrap.dart          # WidgetsFlutterBinding + Supabase.initialize
    app_providers.dart      # MultiRepositoryProvider: repos + use cases
    fast_pos_app.dart       # MaterialApp.router + GoRouter + AuthBloc
  core/
    router/app_router.dart  # GoRouter, redirects, shell branches
    theme/                  # AppTheme, etc.
    widgets/                # Shared UI
  domain/
    entities/               # Bill, profile, session, notifications, …
    repositories/         # Abstract repositories + billing ports
    billing/                # Draft/submission domain types, calculators
  data/
    repositories/           # Supabase-backed *RepositoryImpl
    billing/                # PDF, barcode HTTP impl
    files/                  # Remote PDF download impl
    vision/                 # ML Kit text recognition impl
    mappers/                # DTO ↔ domain
  application/
    auth/                   # Sign in/out, password reset, validators
    billing/                # Observe/submit bills, barcode, OCR, PDF download, …
    profile/                # Profile observe/patch/signature
    registration/           # Register account use case
  presentation/
    account/                # AccountBloc, my_account, widgets
    analytics/              # AnalyticsBloc, monthly_revenue_analysis, widgets
    auth_login/             # AuthBloc, LoginBloc, login_screen, widgets
    billing/                # Draft/submission/voice blocs, bill_generation_page, widgets
    dashboard/
    forgot_password/
    notifications/
    register/
    registration_success/
    shell/
    splash/
    transactions/           # Complete/incomplete screens, bill actions bloc, widgets
test/                       # Unit and bloc tests (bloc_test, mocktail)
android/, ios/, …           # Platform projects
```

---

## Technology stack

| Area | Packages / notes |
|------|-------------------|
| **Framework** | Flutter, Dart ^3.5.1 |
| **Backend** | **Supabase** (`supabase_flutter`) |
| **Navigation** | `go_router` |
| **State** | `flutter_bloc`, `bloc`, `equatable` |
| **UI** | `google_fonts`, `flutter_animate`, `shimmer`, `cached_network_image`, `flutter_slidable`, `fluttertoast`, `flutter_neumorphic`, `font_awesome_flutter`, … |
| **Billing / files** | `pdf`, `printing`, `path_provider`, `open_file`, `share_plus` |
| **Networking** | `http`, `dio` (as used in data/features) |
| **Device** | `image_picker`, `mobile_scanner`, `google_mlkit_text_recognition`, `permission_handler`, `speech_to_text`, `device_info_plus` |
| **Charts** | `fl_chart` |
| **Other** | `intl`, `csv`, `shared_preferences`, `url_launcher`, `email_otp`, `pinput`, `google_sign_in`, … |

> **Note:** An older README mentioned Firebase; the current codebase is centered on **Supabase** for remote/auth/data. If you add Firebase later, update this section.

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible with **Dart 3.5+** (see `environment.sdk` in `pubspec.yaml`).
- A **Supabase project** (URL + anon key) for `Supabase.initialize`.
- For **physical device** features: camera and microphone permissions where required (barcode, OCR, speech). Android/iOS permission strings are configured in the respective platform projects as usual for Flutter.

---

## Getting started

### 1. Clone the repository

```bash
git clone https://github.com/CoderSid007/Fast-Pos.git
cd Fast-Pos
```

(Use your fork or internal remote if different.)

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Create Supabase configuration

The file **`lib/supabase_config.dart`** is **gitignored** (see `.gitignore`). Create it locally at:

`lib/supabase_config.dart`

with a small class that supplies your project URL and anon key, for example:

```dart
abstract final class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY';
}
```

`lib/app/bootstrap.dart` calls `Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey)`.

> **Security:** Never commit real keys. Use CI secrets or local-only files for production keys.

### 4. Run the app

```bash
flutter run
```

Select a device or emulator when prompted.

---

## Configuration

### Supabase

- Required for app startup (`initializeApp`).
- Repository implementations under `lib/data/repositories/` encapsulate Supabase usage; adjust table names and RPCs there if your schema differs.

### Barcode product lookup

- Implemented in **`BarcodeProductLookupRepositoryImpl`** (`lib/data/billing/barcode_product_lookup_repository_impl.dart`).
- Uses the Barcode Lookup HTTP API; replace the placeholder API key constant with a valid key for production, or inject a different implementation of **`BarcodeProductLookupRepository`** via `app_providers.dart` if you change vendors.

### Theme and branding

- `lib/core/theme/app_theme.dart` — light theme entry point used by **`FastPosApp`**.
- Launcher icons: see `flutter_launcher_icons` block in `pubspec.yaml` and `assets/icon/`.

---

## Running and building

```bash
# Analyze
flutter analyze

# Tests
flutter test

# Release APK (example)
flutter build apk

# iOS (on macOS)
flutter build ios
```

---

## Testing

Tests live under **`test/`**:

| Path pattern | Purpose |
|--------------|---------|
| `test/application/` | Use case unit tests (e.g. sign-in, profile observe, barcode lookup forwarder). |
| `test/bloc/` | Bloc tests with **`bloc_test`** (e.g. `BillDraftBloc`, `LoginBloc`, transaction-related blocs). |
| `test/widget_test.dart` | Minimal app smoke test. |

Run all tests:

```bash
flutter test
```

---

## Routing

Defined in **`lib/core/router/app_router.dart`**:

- **`AuthRouterRefresh`** listens to **`AuthBloc`** and notifies GoRouter on a post-frame callback so redirects do not run during illegal build phases.
- **Auth redirect rules:** paths under `/app/…`, legacy `/home`, and full-screen transaction routes require authentication; public routes include `/login`, `/signup`, `/forgot-password`, `/verify-email`.
- **Legacy path aliases** (e.g. `/home` → `/app/dashboard`, `/create-bill` → `/app/new-bill`) are handled in `redirect`.

**Stateful shell** branches (typical tab areas):

- `/app/dashboard` — Dashboard + `DashboardBloc`
- `/app/analysis` — Analytics + `AnalyticsBloc`
- `/app/new-bill` — Bill generation: outer **`BillVoiceAssistBloc`**, **`BillSubmissionBloc`**, **`BillDraftBloc`**
- `/app/notifications` — Notifications + `NotificationsBloc` (requires non-empty user id)
- `/app/profile` — Account + `AccountBloc`

Full-screen routes outside the shell include login, signup, forgot password, verify email, and standalone complete/incomplete transaction screens as configured in the same file.

---

## Presentation: blocs and screens

Non-exhaustive map for onboarding:

| Bloc | Location (typical) | Role |
|------|----------------------|------|
| `AuthBloc` | `presentation/auth_login/bloc/` | Session / auth flow for the whole app |
| `LoginBloc` | same area | Login form and submit |
| `RegisterBloc` | `presentation/register/bloc/` | Registration |
| `ForgotPasswordBloc` | `presentation/forgot_password/bloc/` | Password reset request |
| `DashboardBloc` | `presentation/dashboard/bloc/` | Dashboard aggregates |
| `AnalyticsBloc` | `presentation/analytics/bloc/` | Analytics screen |
| `BillDraftBloc` | `presentation/billing/bloc/` | Bill line items draft |
| `BillSubmissionBloc` | same | Submit pipeline |
| `BillVoiceAssistBloc` | `presentation/billing/bloc/bill_voice_assist/` | Customer name dictation |
| `AccountBloc` | `presentation/account/bloc/` | Profile + mutations |
| `NotificationsBloc` | `presentation/notifications/bloc/` | In-app notifications list |
| `CompleteTransactionsBloc` / `IncompleteTransactionsBloc` | `presentation/transactions/bloc/…` | Transaction lists |
| `TransactionBillActionsBloc` | `presentation/transactions/bloc/bill_actions/` | Per-bill actions |
| `RegistrationSuccessBloc` | `presentation/registration_success/bloc/` | Post-signup UI state |

Screen entry files use **snake_case** filenames (e.g. `login_screen.dart`, `my_account.dart`, `monthly_revenue_analysis.dart`, `complete_transactions_screen.dart`).

---

## Domain and application layers

- **Domain** defines **`AuthRepository`**, **`BillsRepository`**, **`ProfileRepository`**, **`TransactionsRepository`**, **`NotificationsRepository`**, **`RegistrationRepository`**, and auxiliary ports such as **`BarcodeProductLookupRepository`**, **`TextRecognitionRepository`**, **`RemotePdfDownloadRepository`**.
- **Application** exposes use cases consumed via **`RepositoryProvider`** from **`app_providers.dart`** (single composition root). Examples: **`SubmitBillUseCase`**, **`ObserveBillsUseCase`**, **`SignInUseCase`**, **`PatchAccountProfileFieldUseCase`**, **`LookupProductNameByBarcodeUseCase`**, **`ExtractTextLinesFromImagePathUseCase`**, **`DownloadRemotePdfToDeviceUseCase`**, etc.

Adding a feature: prefer **new repository methods + use case** before embedding HTTP or Supabase calls inside widgets.

---

## Data layer and integrations

- **`lib/data/repositories/*_impl.dart`** — Supabase queries and streams, mapped to domain entities.
- **`lib/data/billing/bill_pdf_generator.dart`** — PDF layout and write to app documents.
- **`lib/data/billing/barcode_product_lookup_repository_impl.dart`** — HTTP barcode lookup.
- **`lib/data/vision/text_recognition_repository_impl.dart`** — ML Kit text recognition from an image path.
- **`lib/data/files/remote_pdf_download_repository_impl.dart`** — Download remote PDF bytes to device storage (permissions + paths vary by OS).

Mappers under **`lib/data/mappers/`** keep persistence shapes separate from domain models.

---

## Billing flows (detailed)

1. User edits **customer** fields and **draft lines** (`BillDraftBloc`).
2. Optional: **voice** fills customer name via **`BillVoiceAssistBloc`** and a `BlocConsumer` that writes the transcript into the name `TextEditingController`.
3. **Add product** opens **`showAddBillProductDialog`**, which can:
   - Open **`showBarcodeProductNameBottomSheet`** (camera + `MobileScanner` + lookup use case).
   - Open **`showOcrLinePickerDialog`** (camera + image path + OCR use case + multi-select dialog).
   - Use **speech-to-text** locally in the dialog for the **comment** field.
4. **Generate bill** dispatches **`BillSubmissionRequested`**; **`SubmitBillUseCase`** creates bill + transaction, assigns sequence, writes PDF, returns path.
5. Success feedback is handled by **`BillSubmissionFeedbackListener`**; user may **view** or **share** the PDF.

---

## Code quality and analysis

```bash
flutter analyze   # Should report no errors in a healthy tree
dart format lib test
```

`analysis_options.yaml` enables **`flutter_lints`**. Fix new lints before merging when possible.

---

## Troubleshooting

| Symptom | Things to check |
|---------|-------------------|
| **Crash on startup** | Missing **`lib/supabase_config.dart`** or invalid URL/key. |
| **Auth redirect loops** | `AuthBloc` state vs. `GoRouter` initial location; ensure `AuthRouterRefresh` is wired (see `fast_pos_app.dart`). |
| **Barcode always empty** | API key / network / barcode format; see **`BarcodeProductLookupRepositoryImpl`**. |
| **OCR or camera fails** | OS permissions, emulator without camera, ML Kit model availability. |
| **Speech not working** | Microphone permission, device speech recognition availability, `speech_to_text` initialization errors in debug console. |
| **Tests fail after DI change** | Update `app_providers.dart` and any test fakes that mirror repository registration. |

---

## Repository

- **Upstream (example):** [github.com/CoderSid007/Fast-Pos](https://github.com/CoderSid007/Fast-Pos)  
- **Package name:** `inventopos`  
- **App display title (MaterialApp):** `Fast Pos` (see `lib/app/fast_pos_app.dart`)

For contribution guidelines, open issues, or licensing, refer to the repository owner’s policies on GitHub (add a `LICENSE` and `CONTRIBUTING.md` if you want them explicitly in-tree).

---

## Engineering highlights (v1.0)

- **Offline-first:** Hive local store + `SyncOutboxEntry` + `SyncCoordinator` with `OfflineFirstBillsRepository` (write-local-first, background Supabase push).
- **Inventory:** `products` table, barcode index search, low-stock notifications, atomic stock RPC in `supabase/migrations/`.
- **Bloc-only UI:** `Bloc<Event, State>` everywhere — no Cubit (`scripts/check_no_cubit.sh`).
- **Checkout:** `CheckoutScanBloc` + local barcode lookup; `DiscountStrategy` pattern via `CheckoutBloc`.
- **Analytics P&L:** Revenue minus expenses on Analysis tab (`AnalyticsPnLCard`).
- **Hardware:** ESC/POS Bluetooth printing (`EscPosPrinterRepositoryImpl`).
- **Security:** SHA-256 bill audit hashing (`BillAuditService`) + `local_auth` gate (`AuthenticateUserUseCase`).
- **Bulk I/O:** CSV/XLSX import and CSV/JSON export (`ImportExportPage`, `ExportRepositoryImpl`).
- **Predictive stock:** EMA velocity (`VelocityCalculator`) on product entities.

*Last updated for v1.0 production architecture.*
