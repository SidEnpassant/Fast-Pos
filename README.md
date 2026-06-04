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

---

## Table of contents

1. [What’s in this release](#whats-in-this-release)
2. [Feature catalog](#feature-catalog)
3. [UI & UX (Material 3)](#ui--ux-material-3)
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
17. [Running, building, analyzing](#running-building-analyzing)
18. [Testing](#testing)
19. [Billing flow (end-to-end)](#billing-flow-end-to-end)
20. [Troubleshooting](#troubleshooting)
21. [Repository](#repository)

---

## What’s in this release

This README reflects a **major UX and capability upgrade** beyond a minimal POS demo:

| Area | Highlights |
|------|------------|
| **Home dashboard** | KPI grid (revenue today/month, pending dues, net profit), pulse strip, “needs attention”, grouped quick actions, payment mix, top sellers, low-stock block, recent bills, **AI daily brief**, **reorder alerts** |
| **Analytics** | Full **Analytics Suite** with 5 tabs: Overview, Revenue, P&L, Inventory, Customers — powered by `BusinessAnalytics` + `CustomerAnalytics` |
| **Smart Assistant** | Opt-in AI: voice **Billing Copilot**, Groq **daily brief**, rule + cloud **insights**, velocity-based **reorder** hints |
| **Inventory** | Product CRUD, barcode, low-stock, EMA **velocity** updated on bill submit, import/export |
| **Customers** | Phone-normalized search, detail with bill history, ledger from bills |
| **Expenses** | M3 expenses hub with categories, filters, editor |
| **Transactions** | Completed / pending (partial) bills, PDF view/upload, payment updates |
| **Auth** | Glass login/register, **promo video** background, 3-step registration |
| **Account** | M3 profile sections, KPI chips, signature, **Smart Assistant settings** under Tools |
| **Offline** | Hive bills/products/outbox; sync on connectivity; offline banner |
| **Notifications** | Supabase stream + local notifications; background poll hook |
| **Security** | Bill content hashing, optional biometric gate, RLS on AI tables |

---

## Feature catalog

### Authentication & onboarding

- **Login** — `LoginBloc` + `SignInUseCase`; glass card over looping promo video (`assets/video_asset/`).
- **Register** — 3-step `PageView`: Personal → Business → Billing; `RegisterBloc`; step progress bar.
- **Forgot password** — `ForgotPasswordBloc` + Supabase reset.
- **Post-verify** — `RegistrationSuccessScreen`.
- **Session** — Global `AuthBloc` drives `GoRouter` redirects via `AuthRouterRefresh`.

### Dashboard (`DashboardHubBloc`)

Real-time hub combining bills, products, expenses, customers, sync pending count, notifications, connectivity, and AI unread insights.

**KPI cards (tap targets):**

| Card | Navigates to |
|------|----------------|
| Revenue today | Completed transactions |
| This month | Analytics → Revenue tab |
| Pending dues | Incomplete (partial) transactions |
| Net profit (month) | Analytics → P&L tab |

**Sections:**

- **Pulse strip** — quick stats (bills today, avg ticket, active customers, inventory value).
- **Needs attention** — partial bills, low stock, out of stock, sync pending, offline state.
- **Quick actions** — grouped **Sell** / **Manage** / **Grow** (new bill, sales, pending, inventory, customers, expenses, Smart Assistant, analytics, import, printer).
- **Today’s AI brief** — formatted brief + insight chips (requires Smart Assistant opt-in).
- **Reorder soon** — velocity-based alerts (`InventoryAutomationBloc`).
- **Payment health** — month payment mix (complete / partial / pending).
- **Top sellers** — best SKUs this month by revenue.
- **Low stock alerts** — link to inventory.
- **Recent bills** — latest activity.

Pull-to-refresh reloads hub streams.

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

### Customers

- **CustomersScreen** — search by name/phone (normalized).
- **CustomerDetailScreen** — profile + bill history; no legacy “credit UI” on dashboard.

### Expenses

- **ExpensesScreen** — monthly KPIs, category filters, list, add/edit/delete.
- Feeds **Analytics P&L** and dashboard net profit.

### Analytics (`AnalyticsHubBloc` + `AnalyticsBloc`)

**Route:** `/app/analysis` — `AnalyticsSuiteScreen` with tabs:

1. **Overview** — trends, payment mix, recent bills, expense breakdown, inventory snapshot.
2. **Revenue** — charts + monthly maps (`fl_chart`).
3. **P&L** — revenue vs expenses vs profit.
4. **Inventory** — stock health, low/out lists, retail/cost value.
5. **Customers** — ranks, repeat buyers, outstanding patterns.

Deep links via query: `/app/analysis?tab=revenue` | `pnl` | etc. (`app_shell_navigation.dart`).

### Transactions

- **Complete** — paid/closed bills; PDF actions.
- **Incomplete** — partial payments; collect balance; PDF regen.
- **TransactionBillActionsBloc** — replace signed bill, delete, show PDF.

### Smart Assistant (AI)

See [Smart Assistant & AI](#smart-assistant--ai-groq). Entry points:

- Dashboard quick action **Smart Assistant** → `/ai-hub`
- **My Account → Tools → Smart Assistant** → `/ai-settings`
- **New Bill** app bar → Billing Copilot sheet

### Account (`AccountBloc`)

- Profile header, editable fields (dialog-safe `AccountBloc` capture before `showDialog`).
- Business KPIs (profile completeness).
- **Tools:** Smart Assistant settings, printer setup.
- Signature image upload/replace.

### Notifications

- In-app list; realtime from Supabase.
- `NotificationSyncCoordinator` + local notifications.
- `workmanager` periodic poll (best-effort on Android).

### Hardware & I/O

- **Bluetooth ESC/POS** printing (`PrinterSetupPage`).
- **Biometric** gate use case (`local_auth`) where wired.

---

## UI & UX (Material 3)

The app uses a consistent **Material 3** design language across dashboard, analytics, account, transactions, customers, expenses, and inventory.

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

### Auth UX

- Full-bleed **promo video** with glass morphism card.
- **Auth step progress** on registration.
- Optimized login layout (content spacing on small screens).

### Dashboard UX

- Time-based greeting in header.
- **2×2 KPI grid** on phones (fixed-height cards for reliable taps); responsive grid on tablet/desktop.
- Grouped quick actions with badges (e.g. pending count, low-stock count).
- **AI brief card** — parsed markdown bullets, insight chips, refresh, link to hub (not raw `**markdown**`).

### Analytics UX

- Scrollable tab bar; shimmer placeholders while loading.
- Trend chips (month-over-month %).
- Charts via `fl_chart`.

### Responsive shell

- **Bottom `NavigationBar`** on phones.
- **`NavigationRail`** on medium+ width (`AppBreakpoints`).

### Accessibility & feedback

- Pull-to-refresh on major lists.
- `BillSubmissionFeedbackListener` for success/error snackbars.
- `OfflineBanner` when disconnected.
- Loading overlays on account mutations.

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
| `notify-partial-bills` | Server notification helper (optional) |
| `notify-low-stock` | Server notification helper (optional) |

Shared: `supabase/functions/_shared/groq_client.ts`, `auth.ts`.

### Domain / application / presentation

- **Ports:** `AiGatewayPort`, `AiPreferencesPort`, `AiInsightsPort`, `AutomationJobPort`
- **Use cases:** parse voice, suggestions, daily brief, save preferences, replay offline queue, evaluate reorder alerts, build briefing metrics
- **Blocs:** `AutomationSettingsBloc`, `BillingCopilotBloc`, `BusinessInsightsAiBloc`, `InventoryAutomationBloc`, `AiHubBloc`
- **Offline:** `AiRequestQueue` (Hive) replays failed AI calls when back online

### User settings (`/ai-settings`)

- Enable Smart Assistant (required for all AI calls)
- Daily brief / reorder alerts toggles
- Enhanced context (send barcode hints to Groq)
- Language: English or Hindi/Hinglish
- Privacy copy: Groq runs server-side; user must confirm AI-parsed bill lines

### Models (env overrides)

| Secret | Default | Use |
|--------|---------|-----|
| `GROQ_API_KEY` | — | **Required** |
| `GROQ_MODEL_FAST` | `llama-3.1-8b-instant` | Briefings (plain text) |
| `GROQ_MODEL_SMART` | `llama-3.3-70b-versatile` | Voice parse, suggestions (structured JSON) |

Full deploy guide: [`supabase/README.md`](supabase/README.md).

---

## Dashboard (home)

**Route:** `/app/dashboard`  
**Bloc:** `DashboardHubBloc` (multi-stream fan-in)  
**Widgets:** `dashboard_screen.dart` + `widgets/*`

**Data sources (live):**

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
- **Revenue recognition** — `BillRevenue.recognizedAmount` + calendar-day/month helpers (consistent across dashboard and analytics).

### Bootstrap sequence (`bootstrap.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `LocalStore.init()` — open Hive boxes
3. `Supabase.initialize`
4. Local notifications + Workmanager registration
5. `runApp(fastPosRoot())` — repos, `ConnectivityBloc`, `AuthBloc`, `GoRouter`, `NotificationBridgeListener`, `AiAutomationBridgeListener`

---

## Project structure

```text
Fast-Pos/
├── lib/
│   ├── main.dart
│   ├── supabase_config.dart          # gitignored — you create this
│   ├── app/
│   │   ├── bootstrap.dart
│   │   ├── app_providers.dart        # all RepositoryProviders + use cases
│   │   └── fast_pos_app.dart
│   ├── core/
│   │   ├── router/                   # GoRouter, app_shell_navigation
│   │   ├── design/                   # spacing, radii
│   │   ├── widgets/m3/               # shared M3 components
│   │   ├── notifications/
│   │   └── responsive/               # breakpoints
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   ├── analytics/                # business_analytics, customer_analytics
│   │   ├── billing/
│   │   ├── inventory/                # velocity_calculator
│   │   ├── ai/                       # entities, ports, failures, services
│   │   └── automation/
│   ├── application/
│   │   ├── auth/, billing/, profile/, registration/
│   │   ├── inventory/, customers/, checkout/
│   │   └── ai/                       # parse voice, brief, suggestions, …
│   ├── data/
│   │   ├── local/hive/               # DAOs, boxes
│   │   ├── sync/                     # coordinator, outbox impl
│   │   ├── repositories/           # offline-first bills, customers, …
│   │   ├── ai/                       # supabase gateway, preferences, queue
│   │   └── automation/
│   └── presentation/
│       ├── dashboard/                # hub bloc + rich widgets
│       ├── analytics/                # suite + 5 tab contents
│       ├── billing/ + billing_copilot/
│       ├── inventory/, customers/, expenses/
│       ├── transactions/
│       ├── account/, auth/, auth_login/, register/
│       ├── ai_hub/, automation_settings/, insights/, inventory_automation/
│       ├── shell/, notifications/, import_export/, printer_setup/
│       └── core/                       # connectivity, offline banner, AI bridge
├── supabase/
│   ├── migrations/                   # SQL schema + RLS
│   ├── functions/                    # Edge Functions (Groq, notifications)
│   └── README.md
├── test/
├── assets/                           # images, fonts, icon, video_asset
├── android/, ios/, …
└── README.md
```

---

## Technology stack

| Category | Packages |
|----------|----------|
| **Core** | `flutter`, `supabase_flutter`, `go_router`, `hive_flutter` |
| **State** | `flutter_bloc`, `bloc`, `equatable`, `bloc_concurrency`, `rxdart` |
| **UI** | `google_fonts`, `flutter_animate`, `shimmer`, `cached_network_image`, `flutter_slidable`, `glassmorphism`, `video_player` |
| **Charts** | `fl_chart` |
| **Billing** | `pdf`, `printing`, `share_plus`, `open_file`, `path_provider` |
| **Scan / vision / voice** | `mobile_scanner`, `google_mlkit_text_recognition`, `speech_to_text`, `image_picker`, `permission_handler` |
| **Device** | `connectivity_plus`, `flutter_local_notifications`, `workmanager`, `flutter_blue_plus`, `local_auth`, `device_info_plus` |
| **I/O** | `file_picker`, `excel`, `csv`, `dio`, `http`, `intl` |
| **Security** | `crypto`, `uuid` |
| **Auth extras** | `google_sign_in`, `pinput`, `email_otp` |
| **Dev** | `flutter_test`, `bloc_test`, `mocktail`, `flutter_lints` |

---

## Supabase: schema, migrations, Edge Functions

Apply migrations in order (SQL Editor or `supabase db push`):

| Migration | Contents |
|-----------|----------|
| `20260520000000_v1_schema.sql` | Core schema |
| `20260521100000_v11_production.sql` | Production hardening |
| `20260521110000_fix_notifications_timestamp.sql` | Notifications fix |
| `20260521120000_bill_pdfs_storage_policies.sql` | Bill PDF storage bucket + RLS |
| `20260522120000_ai_automation.sql` | `ai_preferences`, `ai_insights`, `ai_usage_daily`, `automation_jobs`, RLS, `increment_ai_usage` RPC |

**Key tables:** `profiles`, `products`, `bills`, `customers`, `customer_ledger_entries`, `expenses`, `transactions`, `notifications`, plus AI tables above.

**RPCs (examples):** `decrement_stock_for_bill`, `bulk_upsert_products`, `increment_ai_usage`.

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
- **`SyncCoordinator`** — periodic + connectivity-driven outbox processing (started on auth via `AiAutomationBridgeListener`).
- **`OfflineBanner`** in shell when offline.
- **Products/customers/expenses** — Hive cache + background pull; bills are true offline-first.

**Policies:** `SyncPolicy` — server-authoritative products, idempotent bills, LWW expenses/customers.

---

## Routing reference

### Auth redirect

Protected: `/app/*`, `/home`, `/complete-transactions`, `/incomplete-transactions`, `/ai-hub`, `/ai-settings`, etc.

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
| `/app/notifications` | Notifications |
| `/printer-setup`, `/import-export` | Tools |
| `/inventory/editor` | Product editor |
| `/app/bill/inventory-picker` | Bill line picker |

Legacy aliases: `/home` → dashboard, `/create-bill` → new bill, `/AnalyticsDashboard` → analysis.

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
| `BillVoiceAssistBloc` | Customer name STT |
| `BillingCopilotBloc` | Voice lines + Groq parse |
| `CheckoutBloc` / `CheckoutScanBloc` | Totals + barcode |
| `BillInventoryPickerBloc` | Picker flow |
| `AnalyticsBloc` / `AnalyticsHubBloc` | Analytics suite data |
| `BusinessInsightsAiBloc` | AI brief + insights stream |
| `InventoryAutomationBloc` | Reorder alerts |
| `AiHubBloc` | Smart Assistant hub |
| `AutomationSettingsBloc` | AI opt-in settings |
| `ExpensesBloc` | Expenses CRUD |
| `CustomerDetailBloc` | Customer + bills |
| `CompleteTransactionsBloc` / `IncompleteTransactionsBloc` | Transaction lists |
| `TransactionBillActionsBloc` | PDF/sign/delete |
| `AccountBloc` | Profile |
| `NotificationsBloc` | Notification feed |
| `ImportInventoryBloc` | CSV/XLSX import |

---

## Prerequisites

- Flutter SDK (Dart **3.5+**)
- Supabase project (URL + anon JWT key)
- Groq API key (for Smart Assistant — **server-side only**)
- Supabase CLI (recommended for migrations + `functions deploy`)
- Android/iOS: camera, mic, Bluetooth permissions as needed

---

## Getting started

### 1. Clone & dependencies

```bash
git clone https://github.com/CoderSid007/Fast-Pos.git
cd Fast-Pos
flutter pub get
```

### 2. Supabase config (required)

Create **`lib/supabase_config.dart`** (gitignored):

```dart
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJ...', // anon public JWT from Dashboard → API
  );
}
```

Or run with dart-defines:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### 3. Database

Run all files in `supabase/migrations/` on your Supabase project (in filename order).

### 4. Run

```bash
flutter run
```

### 5. Enable Smart Assistant (in app)

**My Account → Tools → Smart Assistant** → enable → Save.  
Then use **Generate today's brief** on the dashboard or **Billing Copilot** on New Bill.

---

## Configuration

| Item | Location |
|------|----------|
| Supabase URL/key | `lib/supabase_config.dart` or dart-defines |
| Barcode Lookup API | `BarcodeProductLookupRepositoryImpl` (replace placeholder key) |
| Launcher icons | `pubspec.yaml` → `flutter_launcher_icons` |
| Groq secrets | Supabase Dashboard → Edge Functions → Secrets |

---

## Deploy Smart Assistant (Groq)

### 1. Project ref

From your Supabase URL: `https://vwciobmlvvhcbasdyvvs.supabase.co` → ref is `vwciobmlvvhcbasdyvvs`.

### 2. Link CLI

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

### 3. Secrets

```bash
supabase secrets set GROQ_API_KEY=gsk_your_key_here
```

### 4. Deploy functions

```bash
supabase functions deploy ai-voice-parse
supabase functions deploy ai-suggest-products
supabase functions deploy ai-briefing
supabase functions deploy ai-complete
supabase functions deploy automation-runner
```

### 5. Smoke test

Dashboard → Edge Functions → `ai-briefing` → POST `{ "smoke": true }` with user JWT.

See [`supabase/README.md`](supabase/README.md) for troubleshooting (`json_schema` vs fast model, etc.).

---

## Running, building, analyzing

```bash
flutter analyze
dart format lib test
flutter test
flutter run
flutter build apk
flutter build ios   # macOS + Xcode
```

---

## Testing

| Path | Covers |
|------|--------|
| `test/domain/business_analytics_test.dart` | Analytics math |
| `test/domain/customer_analytics_test.dart` | Customer metrics |
| `test/domain/ai/voice_command_validator_test.dart` | AI voice validation |
| `test/presentation/dashboard_hub_state_test.dart` | Dashboard KPI derivations |
| `test/presentation/automation_settings_bloc_test.dart` | AI settings bloc |
| `test/application/v11_production_test.dart` | Production use cases |
| `test/bloc/*` | Draft, login, transactions, shell |

```bash
flutter test
```

---

## Billing flow (end-to-end)

1. Open **New Bill** tab → enter customer (optional voice on name field).
2. Add lines: inventory picker, barcode, OCR, manual, or **Billing Copilot** (voice → parse → **confirm**).
3. Set payment method/status, discounts via checkout UI.
4. Submit → local bill + outbox → stock decrement + velocity update → PDF → upload.
5. View in **Sales** or **Pending**; open PDF; print via printer setup.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Crash on startup | Missing/invalid `supabase_config.dart` |
| AI: “Enable Smart Assistant” | Turn on in `/ai-settings` |
| AI: 500 `json_schema` | Redeploy `ai-briefing`; fast model uses plain text (see latest function code) |
| AI: 401 | User must be logged in |
| Brief shows raw `**` | Update app (uses `AiBriefMarkdownView`) |
| Bills not syncing | Check connectivity; `OfflineBanner`; outbox pending count on dashboard |
| Barcode lookup empty | API key in `BarcodeProductLookupRepositoryImpl` |
| Redirect loop | `AuthBloc` + `AuthRouterRefresh` in `fast_pos_app.dart` |

---

## Repository

- **Example remote:** [github.com/CoderSid007/Fast-Pos](https://github.com/CoderSid007/Fast-Pos)
- **Package:** `inventopos`
- **App title:** Fast Pos

### Suggested Play Store one-liner

> Fast POS — bill faster with voice AI, offline invoices, inventory, expenses, and daily shop insights. Built for Indian retailers (₹).

---

*Last updated: production dashboard, Analytics Suite, Smart Assistant (Groq), offline-first sync, and Material 3 UI overhaul.*
