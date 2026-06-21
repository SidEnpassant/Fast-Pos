# Fast POS (InventoPOS)

**Fast POS** is a production-oriented Flutter point-of-sale (POS) app for small retail shops in India and similar markets. It covers billing with PDF invoices, offline-first sync, inventory, customers, expenses, rich analytics, Bluetooth printing, and a **cloud AI layer** (Groq via Supabase Edge Functions) for voice billing, daily briefs, and reorder intelligence.

| | |
|---|---|
| **Display name** | Fast Pos |
| **Dart package** | `inventopos` |
| **SDK** | Dart ^3.5.1 · Flutter 3.x |
| **Backend** | [Supabase](https://supabase.com/) (Auth, Postgres, Storage, Realtime, Edge Functions) |
| **Local store** | [Hive](https://docs.hivedb.org/) (offline cache + sync outbox) |
| **State** | [flutter_bloc](https://pub.dev/packages/flutter_bloc) — **Bloc only, no Cubit** |
| **Navigation** | [go_router](https://pub.dev/packages/go_router) + `StatefulShellRoute` tab shell |
| **Responsive UI**| [flutter_screenutil](https://pub.dev/packages/flutter_screenutil) for universal device scaling |
| **OTA Updates**  | [Shorebird](https://shorebird.dev/) for instant code push |

---

## Table of contents

1. [What’s in this release](#whats-in-this-release)
2. [Feature catalog](#feature-catalog)
3. [UI & UX (Material 3 & Responsiveness)](#ui--ux-material-3--responsiveness)
4. [Smart Assistant & AI (Groq)](#smart-assistant--ai-groq)
5. [Dashboard (home)](#dashboard-home)
6. [Architecture](#architecture)
7. [Project structure](#project-structure)
8. [Technology stack](#technology-stack)
9. [Supabase: schema, migrations, Edge Functions](#supabase-schema-migrations-edge-functions)
10. [Offline-first sync](#offline-first-sync)
11. [Routing reference](#routing-reference)
12. [Blocs & screens reference](#blocs--screens-reference)
13. [Prerequisites](#prerequisites)
14. [Getting started](#getting-started)
15. [Configuration](#configuration)
16. [Deploy Smart Assistant (Groq)](#deploy-smart-assistant-groq)
17. [Running, building, testing & OTA Updates](#running-building-testing--ota-updates)
18. [Billing flow (end-to-end)](#billing-flow-end-to-end)
19. [Troubleshooting](#troubleshooting)
20. [Repository](#repository)

---

## What’s in this release

This release reflects a **major UX, architecture, and capability upgrade** beyond a standard POS:

| Area | Highlights |
|------|------------|
| **Home dashboard** | Lazy loaded KPI grid (revenue today/month, pending dues, net profit), pulse strip, “needs attention”, grouped quick actions, payment mix, top sellers, low-stock block, recent bills, **AI daily brief**, **reorder alerts** |
| **Analytics** | Full **Analytics Suite** with 5 tabs: Overview, Revenue, P&L, Inventory, Customers — powered by `BusinessAnalytics` + `CustomerAnalytics` |
| **Smart Assistant** | Opt-in AI: voice **Billing Copilot**, Groq **daily brief**, rule + cloud **insights**, velocity-based **reorder** hints |
| **Inventory** | Product CRUD, barcode, low-stock, EMA **velocity** updated on bill submit, import/export via CSV/XLSX |
| **Customers** | Phone-normalized search, detail with bill history, ledger from bills |
| **Expenses** | M3 expenses hub with categories, filters, editor |
| **Transactions** | Completed / pending (partial) bills, PDF view/upload, payment updates |
| **Auth & Security** | OTP-based **Password Recovery**, Glass login/register, 3-step registration, Biometric gating, RLS on all AI tables |
| **Account** | M3 profile sections, KPI chips, signature upload, **Smart Assistant settings** under Tools |
| **Offline** | Hive bills/products/outbox; sync on connectivity; offline banner |
| **Notifications** | Supabase stream + local notifications; background poll hook |

---

## Feature catalog

### Authentication & onboarding
- **Login** — `LoginBloc` + `SignInUseCase`; glass card over looping promo video (`assets/video_asset/`).
- **Register** — 3-step `PageView`: Personal → Business → Billing; `RegisterBloc`; step progress bar.
- **Forgot password (OTP)** — Fully native OTP-based recovery flow with a clean UI, `verifyRecoveryOtp`, and secure `updatePassword` logic.
- **Post-verify** — `RegistrationSuccessScreen`.
- **Session** — Global `AuthBloc` drives `GoRouter` redirects via `AuthRouterRefresh`.
- **Biometrics** — Optional biometric gate via `local_auth`.

### Billing & checkout
- **Bill draft** — `BillDraftBloc`; lines with product id, qty, price, comment.
- **Submit** — `SubmitBillUseCase`: validate → create bill (offline-first) → decrement stock → update **velocity EMA** → customer upsert → transaction → sequential bill # → PDF → Supabase PDF upload.
- **Customer voice** — `BillVoiceAssistBloc` on customer name field.
- **Billing Copilot** — `BillingCopilotBloc` + bottom sheet: mic → on-device STT → **Groq** `ai-voice-parse` → **confirm** → add lines (human-in-the-loop).
- **Add product** — inventory picker route, barcode sheet (`mobile_scanner`), OCR (`google_mlkit_text_recognition`), manual dialog.
- **Checkout scan** — `CheckoutScanBloc` resolves barcode to catalog product.
- **Discounts** — `CheckoutBloc` + discount breakdown on submission.
- **PDF** — generate, view, share; cloud storage with signed URLs; regen on payment update.

### Inventory
- List/search, create/edit (`ProductEditorPage`), barcode field.
- **Low stock** thresholds; notifications (server functions available).
- **Import/export** — CSV/XLSX via `ImportExportPage`.
- **Velocity EMA** — `VelocityCalculator`; updated after each successful bill via `UpdateProductVelocityUseCase`.

### Analytics (`AnalyticsHubBloc` + `AnalyticsBloc`)
**Route:** `/app/analysis` — `AnalyticsSuiteScreen` with tabs:
1. **Overview** — trends, payment mix, recent bills, expense breakdown, inventory snapshot.
2. **Revenue** — charts + monthly maps (`fl_chart`).
3. **P&L** — revenue vs expenses vs profit.
4. **Inventory** — stock health, low/out lists, retail/cost value.
5. **Customers** — ranks, repeat buyers, outstanding patterns.
Deep links via query: `/app/analysis?tab=revenue` | `pnl` | etc.

### Transactions
- **Complete** — paid/closed bills; PDF actions.
- **Incomplete** — partial payments; collect balance; PDF regen.
- **TransactionBillActionsBloc** — replace signed bill, delete, show PDF.

### Account (`AccountBloc`)
- Profile header, editable fields (dialog-safe `AccountBloc` capture before `showDialog`).
- Business KPIs (profile completeness).
- **Tools:** Smart Assistant settings, printer setup.
- Signature image upload/replace.

### Hardware & I/O
- **Bluetooth ESC/POS** printing (`PrinterSetupPage`).

---

## UI & UX (Material 3 & Responsiveness)

The app uses a consistent **Material 3** design language augmented with extensive dynamic scaling for multi-device support.

### Responsive Design (`flutter_screenutil`)
Every padding, font size, and radius is dynamically calculated (e.g. `16.w`, `24.h`, `14.sp`). This ensures perfect visual proportions on everything from small 4-inch phones to large format tablets and desktop displays.

### Design tokens (`lib/core/design/`)
- **Spacing** — `AppSpacing` (xs → xl).
- **Radii** — `AppRadii` for cards, chips, sheets.
- **Theme** — `AppTheme.light()` in `lib/core/theme/app_theme.dart` (surface containers, outline variants).

### Shared M3 widgets (`lib/core/widgets/m3/`)
| Widget | Used for |
|--------|----------|
| `AppScreenScaffold` | Consistent app bars + body padding |
| `AppSectionCard` | Titled sections with optional action |
| `AppMetricCard` | KPI tiles (dashboard, analytics, account) |
| `AppQuickActionTile` | Dashboard quick actions + optional badge |
| `AppStatusChip` / `AppSyncStatusChip` | Status pills, sync pending |
| `AppBarcodeScanSheet` | Unified scanner UX |

### Responsive shell
- **Bottom `NavigationBar`** on phones.
- **`NavigationRail`** on medium+ width (`AppBreakpoints`).

---

## Smart Assistant & AI (Groq)

Cloud AI is **opt-in** (`ai_preferences.enabled`). The Flutter app **never** contains `GROQ_API_KEY` — only Supabase Edge Functions call Groq.

### Architecture
```text
Flutter (Bloc → Use case → AiGatewayPort)
    → Supabase.functions.invoke('ai-…')
        → Edge Function (Deno)
            → Groq OpenAI-compatible API (https://api.groq.com/openai/v1)
            → Postgres (ai_insights, ai_usage_daily, …)
```

### Edge Functions (repo)
| Function | Purpose |
|----------|---------|
| `ai-voice-parse` | Transcript + catalog → structured bill lines (structured JSON on **smart** model) |
| `ai-suggest-products` | Prefix + basket → ranked product suggestions |
| `ai-briefing` | Metrics snapshot → markdown brief + rule-based insight rows |
| `ai-complete` | Generic Q&A (future admin chat) |
| `automation-runner` | Cron: automation jobs → briefings / insights |

### User settings (`/ai-settings`)
- Enable Smart Assistant (required for all AI calls)
- Daily brief / reorder alerts toggles
- Enhanced context (send barcode hints to Groq)
- Language: English or Hindi/Hinglish

---

## Dashboard (home)

**Route:** `/app/dashboard`  
**Bloc:** `DashboardHubBloc` (multi-stream fan-in)  

**Data sources (lazy loaded & live):**
- Bills stream → revenue KPIs, partial bills, top products, payment mix
- Products → low stock, inventory value, reorder alerts
- Expenses → month expenses, net profit
- Customers → credit/outstanding helpers
- Sync outbox → pending count
- Notifications → badge count
- AI insights stream → unread count in attention score

---

## Architecture

### Layers
| Layer | Path | Responsibility |
|--------|------|----------------|
| **Domain** | `lib/domain/` | Entities, pure logic (`BusinessAnalytics`, `VelocityCalculator`, `BillRevenue`), repository **interfaces**, AI/automation entities |
| **Application** | `lib/application/` | **Use cases** — orchestration only |
| **Data** | `lib/data/` | Supabase/Hive implementations, PDF, OCR, sync, AI gateway |
| **Presentation** | `lib/presentation/` | Screens, widgets, **Blocs** |
| **Core** | `lib/core/` | Router, theme, M3 widgets, notifications, router helpers |
| **App** | `lib/app/` | `bootstrap.dart`, `app_providers.dart`, `fast_pos_app.dart` |

### Principles
- **DIP:** UI → use cases → ports; `app_providers.dart` composition root.
- **Bloc-only** feature state (sealed events, `Equatable` states).
- **Offline-first bills** via `OfflineFirstBillsRepository` + `SyncRepository` outbox.

---

## Project structure

```text
Fast-Pos/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── bootstrap.dart
│   │   ├── app_providers.dart        # all RepositoryProviders + use cases
│   │   └── fast_pos_app.dart
│   ├── core/
│   │   ├── router/                   # GoRouter, app_shell_navigation
│   │   ├── design/                   # spacing, radii
│   │   ├── widgets/m3/               # shared M3 components
│   │   └── responsive/               # breakpoints
│   ├── domain/
│   │   ├── entities/, repositories/, analytics/, billing/
│   │   ├── inventory/, ai/, automation/
│   ├── application/
│   │   ├── auth/, billing/, profile/, registration/
│   │   ├── inventory/, customers/, checkout/, ai/
│   ├── data/
│   │   ├── local/hive/               # DAOs, boxes
│   │   ├── sync/                     # coordinator, outbox impl
│   │   ├── repositories/           # offline-first bills, customers, …
│   │   └── ai/, automation/
│   └── presentation/
│       ├── dashboard/, analytics/, billing/, billing_copilot/
│       ├── inventory/, customers/, expenses/, transactions/
│       ├── account/, auth/, auth_login/, register/, forgot_password/
│       ├── ai_hub/, automation_settings/, insights/
│       ├── shell/, notifications/, import_export/, printer_setup/
├── supabase/
│   ├── migrations/                   # SQL schema + RLS
│   └── functions/                    # Edge Functions (Groq, notifications)
├── test/
├── assets/                           # images, fonts, icon, video_asset
└── README.md
```

---

## Technology stack

| Category | Packages |
|----------|----------|
| **Core** | `flutter`, `supabase_flutter`, `go_router`, `hive_flutter`, `flutter_dotenv` |
| **State** | `flutter_bloc`, `bloc`, `equatable`, `bloc_concurrency`, `rxdart` |
| **UI** | `flutter_screenutil`, `google_fonts`, `flutter_animate`, `shimmer`, `cached_network_image`, `flutter_slidable`, `glassmorphism`, `video_player` |
| **Charts** | `fl_chart` |
| **Billing** | `pdf`, `printing`, `esc_pos_utils_plus`, `share_plus`, `open_file`, `path_provider` |
| **Scan / vision / voice** | `mobile_scanner`, `google_mlkit_text_recognition`, `speech_to_text`, `image_picker`, `permission_handler` |
| **Device & I/O** | `connectivity_plus`, `flutter_local_notifications`, `workmanager`, `flutter_blue_plus`, `local_auth`, `file_picker`, `excel`, `csv`, `dio`, `http` |
| **Release / OTA** | `shorebird_code_push` |

---

## Supabase: schema, migrations, Edge Functions

Apply migrations in order (SQL Editor or `supabase db push`):

| Migration | Contents |
|-----------|----------|
| `20260520000000_v1_schema.sql` | Core schema |
| `20260521100000_v11_production.sql` | Production hardening |
| `20260521110000_fix_notifications_timestamp.sql` | Notifications fix |
| `20260521120000_bill_pdfs_storage_policies.sql` | Bill PDF storage bucket + RLS |
| `20260522120000_ai_automation.sql` | `ai_preferences`, `ai_insights`, `ai_usage_daily`, `automation_jobs`, RLS |

**IMPORTANT FOR OTP:** In your Supabase Dashboard -> Authentication -> Email Templates -> Reset Password, ensure you are using `{{ .Token }}` instead of a magic link to support the native 6-digit OTP UI flow.

---

## Offline-first sync

```text
User creates bill
  → HiveBillDao (sync_status: pending)
  → HiveOutboxDao (create_bill, decrement_stock, …)
  → SyncRepository.processOutbox when online
  → Supabase Postgres
```
- **`ConnectivityBloc`** — triggers outbox drain + **AI queue replay** on reconnect.
- **`SyncCoordinator`** — periodic + connectivity-driven outbox processing.

---

## Routing reference

### Tab shell (`StatefulShellRoute`)
| Index | Path | Screen |
|-------|------|--------|
| 0 | `/app/dashboard` | `DashboardScreen` + hub + AI blocs |
| 1 | `/app/inventory` | `InventoryScreen` |
| 2 | `/app/new-bill` | `BillGenerationPage` + copilot blocs |
| 3 | `/app/analysis` | `AnalyticsSuiteScreen` |

### Root / modal routes (examples)
| Path | Screen |
|------|--------|
| `/login`, `/signup`, `/forgot-password`, `/verify-email` | Auth |
| `/complete-transactions`, `/incomplete-transactions` | Transactions |
| `/expenses` | Expenses |
| `/customers`, `/customers/:id` | Customers |
| `/ai-hub`, `/ai-settings` | Smart Assistant |
| `/app/profile` | My Account |

---

## Blocs & screens reference

| Bloc | Role |
|------|------|
| `AuthBloc` | Global session |
| `LoginBloc` / `RegisterBloc` / `ForgotPasswordBloc` | Auth forms |
| `ConnectivityBloc` | Online/offline + sync + AI replay |
| `DashboardHubBloc` | Dashboard multi-stream hub |
| `InventoryBloc` | Product list |
| `BillDraftBloc` / `BillSubmissionBloc` | Bill compose + submit |
| `BillVoiceAssistBloc` / `BillingCopilotBloc` | STT and Groq parsing |
| `CheckoutBloc` / `CheckoutScanBloc` | Totals + barcode |
| `AnalyticsBloc` / `AnalyticsHubBloc` | Analytics suite data |
| `BusinessInsightsAiBloc` | AI brief + insights stream |

---

## Prerequisites

- Flutter SDK (Dart **3.5+**)
- Supabase project (URL + anon JWT key)
- Groq API key (for Smart Assistant — **server-side only**)
- Supabase CLI (recommended for migrations + `functions deploy`)
- Android/iOS: camera, mic, Bluetooth permissions as needed

---

## Getting started

1. **Clone & dependencies:**
   ```bash
   git clone https://github.com/CoderSid007/Fast-Pos.git
   cd Fast-Pos
   flutter pub get
   ```
2. **Supabase Config:** Create a **`.env`** file in the root directory:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
3. **Database:** Run migrations from `supabase/migrations/` on your Supabase project.
4. **Run:** `flutter run`

---

## Configuration

| Item | Location |
|------|----------|
| Supabase URL/key | `.env` file |
| Barcode Lookup API | `BarcodeProductLookupRepositoryImpl` |
| Launcher icons | `pubspec.yaml` → `flutter_launcher_icons` |
| Groq secrets | Supabase Dashboard → Edge Functions → Secrets |

---

## Deploy Smart Assistant (Groq)

1. `supabase login` -> `supabase link --project-ref YOUR_PROJECT_REF`
2. `supabase secrets set GROQ_API_KEY=gsk_your_key_here`
3. `supabase functions deploy ai-voice-parse` (Deploy all functions individually)

---

## Running, building, testing & OTA Updates

This application integrates **Shorebird** for instant Over-The-Air (OTA) updates, bypassing Play Store review times for minor patches.

**Standard Build (Testing):**
```bash
flutter analyze
flutter test
flutter run
flutter build apk
```

**Production Release Build (Shorebird Enabled):**
Do *not* use `flutter build appbundle`. Instead, use:
```bash
shorebird release android
```
*(Note: Windows users may need to run `git config --system core.longpaths true` if Shorebird encounters path length issues).*

**Pushing an OTA Patch (Shorebird):**
```bash
shorebird patch android
```

---

## Billing flow (end-to-end)

1. Open **New Bill** tab → enter customer.
2. Add lines: inventory picker, barcode, OCR, manual, or **Billing Copilot**.
3. Set payment method/status, discounts via checkout UI.
4. Submit → local bill + outbox → stock decrement + velocity update → PDF → upload.
5. View in **Sales** or **Pending**; open PDF; print via printer setup.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| AI: 500 `json_schema` | Redeploy `ai-briefing`; fast model uses plain text. |
| Bills not syncing | Check connectivity; watch dashboard sync outbox counter. |
| Shorebird path error | Run `git config --system core.longpaths true` |
| OTP link opens browser | Fix Supabase Email template to use `{{ .Token }}`. |
| UI elements clipped | Ensure `ScreenUtilInit` wraps the `MaterialApp` in `fast_pos_app.dart`. |
| Barcode lookup empty | Add API key to `BarcodeProductLookupRepositoryImpl`. |
| Redirect loop | Check `AuthBloc` + `AuthRouterRefresh` in `fast_pos_app.dart`. |

---

## Repository

- **Example remote:** [github.com/CoderSid007/Fast-Pos](https://github.com/CoderSid007/Fast-Pos)
- **Package:** `inventopos`
- **App title:** Fast Pos

### Suggested Play Store one-liner

> Smart POS, Billing, Inventory & AI-powered business analytics in one app!
