# Fast POS (InventoPOS)

**Fast POS** is a production-oriented, feature-rich Flutter point-of-sale (POS) app tailored for small retail shops and businesses. It encompasses a massive suite of features from billing with PDF invoices, offline-first sync, inventory management, customer relationships, expense tracking, rich analytics, Bluetooth printing, to an advanced **cloud AI layer** (Groq via Supabase Edge Functions) for voice billing, daily briefs, automations, and intelligent business insights.

| | |
|---|---|
| **Display name** | Fast POS |
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
3. [Smart Assistant, AI & Automation](#smart-assistant-ai--automation)
4. [UI & UX (Material 3 & Responsiveness)](#ui--ux-material-3--responsiveness)
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
18. [Troubleshooting](#troubleshooting)
19. [Repository](#repository)

---

## What’s in this release

Fast POS has evolved far beyond a standard POS system, incorporating deep business logic and automation:

| Area | Highlights |
|------|------------|
| **Home Dashboard** | Lazy loaded KPI grid, pulse strip, grouped quick actions, top sellers, low-stock block, recent bills, **AI daily brief**, **reorder alerts**. |
| **Billing & Checkout** | Full billing flows with discounts, barcode scanning, OCR parsing, **Repeat Orders**, offline drafts, and PDF generation. |
| **Inventory & Audits** | Real-time product tracking, **Live Stock Audits**, CSV/XLSX Import/Export, barcode generation, and velocity (EMA) tracking. |
| **Supply Chain** | Full **Purchase Orders (PO)** lifecycle and **Suppliers** directory (create, issue, receive full/partial stock). |
| **Returns & Credits** | Complete **Returns** workflow with automatic inventory restock and **Credit Note** issuance/tracking. |
| **Daybook & Cash** | Daily ledger tracking cash-in and cash-out (Daybook). |
| **Customers & Loyalty** | Phone-normalized customer CRM with ledger, messaging, and a highly configurable **Loyalty Point System** tied to checkout. |
| **Expenses & Taxes** | M3 expenses hub + **Tax Settings** for granular multi-tax/GST setups. |
| **Analytics Suite** | 5 comprehensive tabs: Overview, Revenue, P&L, Inventory, Customers. |
| **Smart Assistant** | Voice **Billing Copilot**, Groq daily briefs, rule + cloud insights, and automated scheduled background jobs. |
| **Auth & Security** | OTP-based recovery, seamless signup, Biometric gating, strict RLS on all backend tables. |

---

## Feature catalog

### Authentication & Onboarding
- **Login** — OTP login & Email/Password with glassmorphism UI over a looping promo video.
- **Register** — 3-step dynamic flow (Personal → Business → Billing) with email OTP verification.
- **Forgot password** — Fully native OTP-based recovery flow (`verifyRecoveryOtp` & `updatePassword`).
- **Session & Routing** — Handled via `AuthBloc` driving `GoRouter` redirects without context issues.
- **Biometrics** — Optional biometric gating via `local_auth`.

### Billing & Checkout
- **Bill Drafts** — Add products, alter quantities, inject manual items, and apply dynamic tax/discounts.
- **Smart Add** — Barcode scanner (`mobile_scanner`), ML Kit OCR (`google_mlkit_text_recognition`), and manual catalog picker.
- **Billing Copilot** — Mic → on-device STT → **Groq** `ai-voice-parse` → parse natural language directly into bill lines.
- **Repeat Orders** — Instantly reconstruct a cart based on past customer purchases.
- **Checkout** — Apply Loyalty Points, partial payments, generate sequential invoice numbers, and auto-decrease stock.
- **PDF & Print** — Generates rich invoices with uploaded business signatures, outputs to ESC/POS Bluetooth printers, or shares via native sheets.

### Inventory & Audits
- **Catalog** — Comprehensive product CRUD with categories, barcodes, and dynamic cost/retail tracking.
- **Low Stock & Velocity** — EMA (Exponential Moving Average) velocity updated per bill, firing low-stock triggers.
- **Stock Audits** — Reconcile physical vs. system stock via live audit sessions, capturing variance.
- **Import/Export** — Bulk catalog management using CSV/XLSX integration.

### Purchasing & Suppliers
- **Suppliers** — Maintain supplier contact, GST, and business details.
- **Purchase Orders (POs)** — Draft, issue, and manage supplier orders.
- **Receive Stock** — Execute full or partial PO receipts, automatically updating current inventory levels.

### Returns & Credit Notes
- **Process Returns** — Select a past bill, mark returned items, choose to restock inventory or write-off.
- **Credit Notes** — Issue digital credit notes for returned value, applying them natively against future customer bills.

### Daybook & Expenses
- **Daybook** — Real-time cash register tracking opening balances, daily cash-in (sales), cash-out (expenses), and closing balances.
- **Expenses** — Track operational expenditures with categorization and receipt attachments.

### Customers, Loyalty & Messaging
- **CRM** — Unified customer database tracking outstanding balances and lifetime value.
- **Loyalty Program** — Configure earnings (X points per $) and redemptions (Y points = $Z discount), tracked per customer.
- **Batch Messaging Queue** — Send targeted promotional or transactional SMS/Emails to customer segments.

### Analytics Suite (`AnalyticsHubBloc`)
1. **Overview** — KPI trends, payment mix, recent activities.
2. **Revenue** — Rich charting with `fl_chart`.
3. **P&L** — Profit & Loss visualizations.
4. **Inventory** — Stock health, valuation, and dead-stock identification.
5. **Customers** — Retention ranks, top buyers, and outstanding ledgers.

---

## Smart Assistant, AI & Automation

Cloud AI is **opt-in** (`ai_preferences.enabled`). The Flutter app **never** stores the `GROQ_API_KEY` — all inference happens securely via Supabase Edge Functions.

### AI Capabilities
- **Voice Parsing (`ai-voice-parse`)**: Transcript + catalog → structured bill lines.
- **Daily Brief (`ai-briefing`)**: Compiles metrics into a markdown brief + actionable insight rows.
- **Automation Scheduler**: CRON jobs executed via the `automation-runner` Edge Function to pre-compute insights and run maintenance tasks.

### Automation & Configuration
- **Settings**: Manage Smart Assistant, reorder alerts, and background execution frequency.
- **Context Awareness**: Configurable context (e.g., sending barcode metadata securely to Groq).
- **Language**: Support for English and Hindi/Hinglish.

---

## UI & UX (Material 3 & Responsiveness)

The app uses a strict **Material 3** design language augmented with dynamic scaling for multi-device support via `flutter_screenutil`.

### Core Design Principles
- **Responsive Geometry** — Paddings, fonts, and radii scale fluidly (`16.w`, `24.h`, `14.sp`).
- **Glassmorphism & Animation** — Heavy use of blurred backgrounds, micro-interactions (`flutter_animate`), and skeleton loaders (`AppShimmer`).
- **Design Tokens** — Managed via `AppSpacing`, `AppRadii`, and `AppTheme.light()`.

### Shared M3 Widgets
- `AppScreenScaffold`, `AppSectionCard`, `AppMetricCard`, `AppQuickActionTile`, `AppBarcodeScanSheet`.

---

## Dashboard (home)

The central operational hub (`/app/dashboard`). Lazy loads data via multi-stream fan-in (`DashboardHubBloc`):
- **Sales & Revenue** (Today, Monthly, Net Profit).
- **Pulse Strip** (Real-time updates on active bills, pending syncs).
- **Quick Actions** (Generate Bill, Add Product, Process Return, Record Expense).
- **AI Daily Brief** (Top sellers, low stock warnings, reorder suggestions).

---

## Architecture

Built with a strict separation of concerns, heavily utilizing Domain-Driven Design (DDD) principles:

| Layer | Responsibility |
|--------|----------------|
| **Domain** | Entities, business logic (`VelocityCalculator`, `BillRevenue`), interfaces. |
| **Application**| **Use Cases** — Orchestrates logic between repositories and blocs. |
| **Data** | Supabase/Hive implementations, offline sync outbox, AI gateways. |
| **Presentation**| Screens, widgets, and **Blocs** (Strictly `flutter_bloc` with sealed states/events). |
| **Core** | Router configurations (`GoRouter`), theme tokens, shared components. |

---

## Project structure

```text
Fast-Pos/
├── lib/
│   ├── main.dart
│   ├── app/                    # Composition root (app_providers), Bootstrap
│   ├── core/                   # Router, design tokens, shared M3 widgets
│   ├── domain/                 # Interfaces, entities
│   ├── application/            # Use cases (Auth, Billing, Inventory, AI)
│   ├── data/                   # Supabase repos, Hive DAOs, Sync coordinators
│   └── presentation/           # Feature folders containing views & blocs
├── supabase/
│   ├── migrations/             # SQL schema + RLS
│   └── functions/              # Deno Edge Functions
├── assets/                     # Images, fonts, animations, videos
└── README.md
```

---

## Technology stack

| Category | Packages |
|----------|----------|
| **Core** | `flutter`, `supabase_flutter`, `go_router`, `hive_flutter`, `flutter_dotenv` |
| **State** | `flutter_bloc`, `bloc`, `equatable`, `bloc_concurrency`, `rxdart` |
| **UI** | `flutter_screenutil`, `google_fonts`, `flutter_animate`, `shimmer`, `glassmorphism`, `video_player` |
| **Charts** | `fl_chart` |
| **Billing / Print** | `pdf`, `printing`, `esc_pos_utils_plus`, `share_plus` |
| **Hardware** | `mobile_scanner`, `google_mlkit_text_recognition`, `speech_to_text`, `flutter_blue_plus`, `local_auth` |
| **Platform I/O**| `connectivity_plus`, `workmanager`, `excel`, `csv`, `file_picker` |
| **Release** | `shorebird_code_push` |

---

## Supabase: schema, migrations, Edge Functions

Apply migrations in order using Supabase CLI:

| Migration | Contents |
|-----------|----------|
| `20260520000000_v1_schema.sql` | Core schema |
| `20260521100000_v11_production.sql` | Production hardening |
| `20260521110000_fix_notifications_timestamp.sql` | Notifications fix |
| `20260521120000_bill_pdfs_storage_policies.sql` | Bill PDF storage bucket + RLS |
| `20260522120000_ai_automation.sql` | AI usage tracking, background automation tables, RLS |

**IMPORTANT FOR OTP:** In the Supabase Dashboard -> Authentication -> Email Templates -> Reset Password, ensure you use `{{ .Token }}` instead of a magic link for the native 6-digit OTP UI flow.

---

## Offline-first sync

Robust offline capabilities powered by Hive local storage:
1. **Action** → Saved locally to Hive (`sync_status: pending`).
2. **Outbox** → Appended to `HiveOutboxDao` (e.g., `create_bill`, `decrement_stock`).
3. **Sync** → `SyncCoordinator` processes the queue securely in the background upon connectivity restoration.

---

## Routing reference

Powered by `go_router` with a `StatefulShellRoute` for seamless tab navigation.

**Tab Shell:** `/app/dashboard`, `/app/inventory`, `/app/new-bill`, `/app/analysis`  
**Top-Level Routes:**
- `/login`, `/signup`, `/forgot-password`
- `/complete-transactions`, `/incomplete-transactions`
- `/returns/new`, `/credit-notes`
- `/purchase-orders`, `/suppliers`
- `/daybook`, `/expenses`
- `/stock-audit`, `/import-export`, `/printer-setup`
- `/ai-hub`, `/automation-jobs`

---

## Blocs & screens reference

- `AuthBloc` / `LoginBloc` / `RegisterBloc`: Global session and auth forms.
- `DashboardHubBloc`: Multi-stream data aggregator.
- `BillSubmissionBloc` / `CheckoutBloc`: Orchestrates billing business logic.
- `ReturnBloc` / `CreditNotesBloc`: Handles complex return restocks.
- `PurchaseOrderBloc` / `SuppliersBloc`: Manages supply chain data.
- `DayBookBloc` / `ExpensesBloc`: Financial ledger management.
- `LoyaltyBloc`: Computes and applies points/discounts dynamically.
- `SyncCoordinator`: Background data synchronization.

---

## Prerequisites

- Flutter SDK (Dart **3.5+**)
- Supabase project (URL + anon JWT key)
- Groq API key (for Smart Assistant — **server-side only**)
- Supabase CLI
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
| Launcher icons | `pubspec.yaml` → `flutter_launcher_icons` |
| Groq secrets | Supabase Dashboard → Edge Functions → Secrets |

---

## Deploy Smart Assistant (Groq)

1. `supabase login` -> `supabase link --project-ref YOUR_PROJECT_REF`
2. `supabase secrets set GROQ_API_KEY=gsk_your_key_here`
3. `supabase functions deploy ai-voice-parse` (Deploy all functions individually)

---

## Running, building, testing & OTA Updates

This application integrates **Shorebird** for instant Over-The-Air (OTA) updates, bypassing app store review times for minor patches.

**Standard Build:**
```bash
flutter analyze
flutter test
flutter run
flutter build apk
```

**Production Release Build (Shorebird Enabled):**
```bash
shorebird release android
```
*(Windows users: Run `git config --system core.longpaths true` if Shorebird fails due to path length issues).*

**Pushing an OTA Patch (Shorebird):**
```bash
shorebird patch android
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Redirect loop | Check `AuthBloc` + `AuthRouterRefresh` routing rules in `app_router.dart`. |
| OTP link opens browser | Fix Supabase Email template to use `{{ .Token }}` natively. |
| Shorebird path error | Run `git config --system core.longpaths true`. |
| AI / Automation errors | Check Supabase Edge Function logs; ensure GROQ_API_KEY is set. |

---

## Repository

- **Package:** `inventopos`
- **App title:** Fast POS

> Smart POS, Billing, Inventory, Supply Chain, and AI-powered analytics in one robust application!
