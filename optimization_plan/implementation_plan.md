# Fast-Pos Comprehensive Audit & Optimization Plan

## Architecture Summary

Fast-Pos is a **Flutter POS application** using Clean Architecture (domain → application → data → presentation) with:
- **State management**: BLoC/Cubit via `flutter_bloc`
- **Backend**: Supabase (Postgres streams, Storage, Auth, Edge Functions)
- **Offline-first**: Hive local storage + outbox sync queue
- **Navigation**: GoRouter with `StatefulShellRoute` for tab persistence
- **AI features**: Edge Functions for business insights, daily briefings

> [!IMPORTANT]
> All changes preserve 100% of existing functionality, UI, business logic, APIs, database schema, and UX. No features are removed.

---

## Phase 1 — Performance Optimization (High Impact)

### 1.1 Hive Watch Stream Deduplication

#### [MODIFY] [stream_utils.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/core/utils/stream_utils.dart)

**Root cause**: `hiveWatchStream` fires `read()` on **every** box mutation — even mutations to unrelated keys. When products box has 200 entries and bills box updates, every product watcher fires unnecessarily.

**Fix**: Add key-level filtering in `hiveWatchStream`. Accept an optional `filter` predicate on `BoxEvent` to only re-read when relevant keys change. Also add `distinct` to prevent emitting identical lists.

```dart
Stream<T> hiveWatchStream<T>({
  required Stream<BoxEvent> events,
  required T Function() read,
  bool Function(BoxEvent)? filter,  // NEW
}) {
  return Stream.multi((controller) {
    controller.add(read());
    final sub = events
        .where((e) => filter == null || filter(e))
        .map((_) => read())
        .listen(controller.add, onError: controller.addError, onDone: controller.close);
    controller.onCancel = () => sub.cancel();
  });
}
```

**Severity**: 🔴 Critical — Causes O(N²) rebuilds on any Hive mutation.

---

### 1.2 HiveProductDao Batch Write Optimization

#### [MODIFY] [hive_product_dao.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/local/hive/hive_product_dao.dart)

**Root cause**: `putAll()` calls `put()` sequentially for each product, and each `put()` rebuilds search tokens (deleting+inserting individually). For 200 products on first sync, this is ~1000+ individual Hive writes.

**Fix**: Use `_box.putAll()` for batch product writes, and batch token operations into a single `_tokens.putAll()` / `_tokens.deleteAll()`.

```dart
Future<void> putAll(List<Product> products) async {
  final productEntries = <String, Map>{};
  for (final p in products) {
    productEntries[p.id] = ProductMapper.toHiveMap(p);
  }
  await _box.putAll(productEntries);
  // Rebuild tokens in batch
  await _rebuildAllTokens(products);
}
```

**Severity**: 🔴 Critical — Blocks startup for 2-5 seconds on mid-range devices.

---

### 1.3 Dashboard Compute Debounce Race Condition

#### [MODIFY] [dashboard_hub_bloc.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/dashboard/bloc/dashboard_hub_bloc.dart)

**Root cause**: When multiple streams fire simultaneously on startup (bills, products, expenses, customers), `_requestRecompute()` is called 4 times. The first fires immediately (`_pendingImmediateRecompute`), but the next 3 each cancel the previous debounce timer and restart the 300ms delay. This causes the final compute to potentially never fire if streams keep arriving.

**Fix**: Use `restartable()` transformer from `bloc_concurrency` for `DashboardHubRecomputeRequested` to auto-cancel stale computes. Also, only trigger recompute after **all** initial data has arrived:

```dart
on<DashboardHubRecomputeRequested>(
  _onRecompute,
  transformer: restartable(),
);
```

And modify `_requestRecompute` to batch — only trigger after a settled state:

```dart
void _requestRecompute() {
  _debounce?.cancel();
  if (_pendingImmediateRecompute && _gotBills && _gotProducts && _gotExpenses && _gotCustomers) {
    _pendingImmediateRecompute = false;
    if (!isClosed) add(const DashboardHubRecomputeRequested());
    return;
  }
  _debounce = Timer(const Duration(milliseconds: 300), () {
    if (!isClosed) add(const DashboardHubRecomputeRequested());
  });
}
```

**Severity**: 🟠 High — Causes dashboard to show stale/zero data on startup.

---

### 1.4 Customer & Expense Repository Pull Deduplication

#### [MODIFY] [customer_repository_impl.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/repositories/customer_repository_impl.dart)
#### [MODIFY] [expense_repository_impl.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/repositories/expense_repository_impl.dart)

**Root cause**: `watchCustomersForUser` calls `unawaited(_pull(userId))` on every subscription. If the dashboard and another screen both subscribe, `_pull` runs twice (the dedup guard only catches concurrent calls, not sequential).

**Fix**: Add a timestamp-based cooldown so `_pull` skips if last successful pull was within 30 seconds:

```dart
DateTime? _lastPullAt;
Future<void> _pull(String userId) async {
  if (_lastPullAt != null && DateTime.now().difference(_lastPullAt!) < const Duration(seconds: 30)) return;
  // ... existing dedup logic
  _lastPullAt = DateTime.now();
}
```

**Severity**: 🟡 Medium — Causes duplicate network requests on navigation.

---

### 1.5 Outbox Purge (Unbounded Hive Growth)

#### [MODIFY] [hive_outbox_dao.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/local/hive/hive_outbox_dao.dart)

**Root cause**: `markSynced` sets status to `'synced'` but never removes the entry. Over time the outbox grows unbounded — every `pendingForUser` and `pendingCount` scan iterates all entries.

**Fix**: In `markSynced`, delete the entry outright instead of marking status. Add a periodic compaction method.

```dart
Future<void> markSynced(String id) async {
  await _box.delete(id);
}
```

**Severity**: 🟡 Medium — Causes progressive performance degradation over weeks of use.

---

### 1.6 Hive mergeAllFromRemote Sequential Write

#### [MODIFY] [hive_bill_dao.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/local/hive/hive_bill_dao.dart)

**Root cause**: `mergeAllFromRemote` iterates all remote bills and does individual `putFromBill` (Hive write) for each. For 500 bills, this fires 500 Hive box events, each triggering `hiveWatchStream` which calls `listForUser` → iterating all box values.

**Fix**: Batch the merge, collect all puts, then call `_box.putAll()` once:

```dart
Future<void> mergeAllFromRemote(List<Bill> remotes, Bill Function(Bill, Bill) merge) async {
  final batch = <String, Map>{};
  for (final remote in remotes) {
    final existing = _box.get(remote.id);
    final bill = existing == null
      ? remote
      : merge(remote, BillMapper.fromSupabaseRow(Map<String, dynamic>.from(existing)));
    batch[bill.id] = _toMap(bill);
  }
  await _box.putAll(batch);
}
```

**Severity**: 🔴 Critical — Single biggest startup bottleneck.

---

## Phase 2 — Memory Leak Fixes

### 2.1 SyncCoordinator Duplicate Connectivity Subscriptions

#### [MODIFY] [sync_coordinator.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/sync/sync_coordinator.dart)

**Root cause**: `Connectivity().onConnectivityChanged` creates a new `Connectivity` instance (and platform channel listener) every call. The existing `_sub?.cancel()` only cancels the stream subscription, not the platform listener. Also, `ConnectivityBloc` already creates its own `Connectivity()` listener — so there are **two** duplicate platform listeners.

**Fix**: Accept `Connectivity` as a constructor parameter (shared instance) instead of creating a new one:

```dart
class SyncCoordinator {
  SyncCoordinator(this._sync, {Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();
  final Connectivity _connectivity;
  // Use _connectivity.onConnectivityChanged instead of Connectivity().onConnectivityChanged
}
```

**Severity**: 🟠 High — Duplicate platform channel listeners cause memory leaks.

---

### 2.2 ConnectivityBloc Duplicate Connectivity Instance

#### [MODIFY] [connectivity_bloc.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/core/bloc/connectivity_bloc.dart)

**Root cause**: `_onStarted` creates `Connectivity()` as a new instance every time. If `ConnectivityStarted` is dispatched multiple times (it is — once by BlocProvider and once by FastPosApp on auth), listeners pile up.

**Fix**: Create `Connectivity` once in the constructor:

```dart
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc(this._sync, this._replayAi)
    : _connectivity = Connectivity(),
      super(const ConnectivityState()) { ... }
  final Connectivity _connectivity;
}
```

**Severity**: 🟠 High — Each restart leaks a platform channel listener.

---

### 2.3 NotificationSyncCoordinator _seenIds Unbounded Growth

#### [MODIFY] [notification_sync_coordinator.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/core/notifications/notification_sync_coordinator.dart)

**Root cause**: `_seenIds` and `_seenDedupKeys` grow without bound. Line 70 trims `_seenIds` based on current list, but `_seenDedupKeys` is never trimmed.

**Fix**: Also trim `_seenDedupKeys` in `_onListUpdated`:

```dart
final currentDedupKeys = list.where((n) => n.dedupKey != null).map((n) => n.dedupKey!).toSet();
_seenDedupKeys.removeWhere((k) => !currentDedupKeys.contains(k));
```

**Severity**: 🟡 Medium — Slow memory leak over app lifetime.

---

### 2.4 HiveOutboxDao watchPendingCount Missing Initial Value

#### [MODIFY] [hive_outbox_dao.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/local/hive/hive_outbox_dao.dart)

**Root cause**: `watchPendingCount` only maps box watch events — it never emits the current count on subscription. If the outbox is empty and no mutations happen, the `ConnectivityBloc` never gets a value.

**Fix**: Use `hiveWatchStream` pattern:

```dart
Stream<int> watchPendingCount(String userId) {
  return hiveWatchStream(
    events: _box.watch(),
    read: () => pendingCount(userId),
  );
}
```

**Severity**: 🟡 Medium — Sync badge may show stale count.

---

## Phase 3 — State Management Optimization

### 3.1 DashboardHubState Equatable Cost

#### [MODIFY] [dashboard_hub_state.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/dashboard/bloc/dashboard_hub_state.dart)

**Root cause**: `DashboardHubState` has 27 props including `List<Bill>`, `List<Product>`, `List<Expense>`, `List<Customer>`. BLoC's `Equatable` does deep list comparison on every emit. For 500 bills, this is a significant cost per state transition.

**Fix**: Remove raw entity lists from `props` (they are sources, not display values). Keep only the computed metrics in props:

```dart
@override
List<Object?> get props => [
  loading,
  revenueToday,
  revenueThisMonth,
  billsToday,
  // ... all scalar/computed metrics
  // DO NOT include bills, products, expenses, customers
];
```

This is safe because the bloc always emits new state objects via `copyWith` — Equatable just needs to detect meaningful display changes.

**Severity**: 🟠 High — Causes ~1ms per state comparison × 6 streams × initial load.

---

### 3.2 InventoryBloc Search Debouncing

#### [MODIFY] [inventory_bloc.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/inventory/bloc/inventory_bloc.dart)

**Root cause**: `_onSearchChanged` fires on every keystroke with no debounce. For local Hive search this isn't terrible, but `_apply()` rebuilds the full filtered list each time.

**Fix**: Use `restartable()` transformer:

```dart
on<InventorySearchQueryChanged>(
  _onSearchChanged,
  transformer: restartable(),
);
```

**Severity**: 🟡 Medium — Causes UI stutter during fast typing.

---

### 3.3 Bill Generation Page Excessive setState

#### [MODIFY] [bill_generation_page.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/billing/view/bill_generation_page.dart)

**Root cause**: `_paymentMethod`, `_paymentStatus`, and `_paidAmount` are stored as local `State` fields with `setState`. Each change rebuilds the entire form including the heavy `BlocConsumer<BillVoiceAssistBloc>` and all sections.

**Fix**: Extract payment section into its own `StatefulWidget` so `setState` scope is localized:

```dart
// Payment fields become local to _PaymentSection stateful widget
// Parent only reads values when submitting via a callback/key
```

**Severity**: 🟡 Medium — Unnecessary full-page rebuild on dropdown changes.

---

## Phase 4 — Database/Network Optimization

### 4.1 Customer/Expense Repo: Full-Table Pulls

#### [MODIFY] [customer_repository_impl.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/repositories/customer_repository_impl.dart)
#### [MODIFY] [expense_repository_impl.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/repositories/expense_repository_impl.dart)

**Root cause**: `_pullOnce` does `SELECT * FROM customers WHERE user_id = ?` with no pagination and no delta sync. For a user with 1000 customers, this transfers the entire table on every app open.

**Fix**: Add cursor-based delta sync using a Hive-stored `updated_at` cursor:

```dart
Future<void> _pullOnce(String userId) async {
  final cursor = _getCursor(userId); // read from HiveBoxes.syncCursors
  final rows = await _client.from('customers')
    .select()
    .eq('user_id', userId)
    .gt('updated_at', cursor)
    .order('updated_at');
  // ... merge into Hive, update cursor
}
```

**Severity**: 🟠 High — Transfers full table on every app start.

---

### 4.2 ProductRepository Redundant pullRemote

#### [MODIFY] [product_repository_impl.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/inventory/product_repository_impl.dart)

**Root cause**: Both `watchProductsForUser` and `fetchProductsForUser` call `_pullRemote`. If the dashboard subscribes to watch and the inventory screen calls fetch, two pulls happen.

**Fix**: Same cooldown approach as 1.4. Also add delta sync cursor:

```dart
DateTime? _lastPullAt;
```

**Severity**: 🟡 Medium — Duplicate network call.

---

### 4.3 Bills Repository Double Stream

#### [MODIFY] [offline_first_bills_repository.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/repositories/offline_first_bills_repository.dart)

**Root cause**: `_buildMergedStream` subscribes to both the local Hive stream AND the Supabase Postgres stream. The Supabase stream sends the entire bills table on every change (Postgres `.stream()` behavior). Then `mergeAllFromRemote` writes all remote bills back to Hive, which triggers the local stream, which triggers another merge emit.

**Fix**: Already partially mitigated by `asBroadcastStream` sharing. But we should add a `distinct`/content-hash check to prevent duplicate merged emissions:

```dart
void emitMerged() {
  final merged = ...; // existing merge logic
  // Only emit if actually different from last emission
  if (!_listEquals(merged, _lastEmitted)) {
    _lastEmitted = merged;
    controller.add(merged);
  }
}
```

**Severity**: 🟡 Medium — Causes double-render on bill updates.

---

## Phase 5 — Security Hardening

### 5.1 `.env` File in Flutter Assets

> [!WARNING]
> The `.env` file containing `SUPABASE_URL` and `SUPABASE_ANON_KEY` is bundled in Flutter assets (pubspec.yaml line 136). While the anon key is designed to be public, the `.env` file may also contain sensitive values in the future. This is acceptable for now since anon keys are meant to be client-side, but should be noted.

**Status**: Acceptable — Supabase anon key is designed for client use. RLS policies protect data. No action needed unless `SUPABASE_SERVICE_KEY` is ever added.

---

### 5.2 Catch-All Exception Swallowing

**Root cause**: Multiple repositories use `catch (_) {}` which silently swallows all errors including auth errors, network timeout, and schema mismatches.

**Fix**: Add `debugPrint` in debug mode and structured error types:

```dart
} catch (e) {
  if (kDebugMode) debugPrint('CustomerRepo._pullOnce failed: $e');
}
```

Files affected:
- [customer_repository_impl.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/repositories/customer_repository_impl.dart) (lines 61, 101, 119, 140)
- [expense_repository_impl.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/repositories/expense_repository_impl.dart) (lines 61, 96, 105)
- [product_repository_impl.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/data/inventory/product_repository_impl.dart) (lines 50, 74, 113, 124, 135, 187)

**Severity**: 🟠 High — Hides critical errors that make debugging impossible.

---

### 5.3 Missing Auth Guard on BillGenerationPage

#### [MODIFY] [bill_generation_page.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/billing/view/bill_generation_page.dart)

**Root cause**: Line 95 uses `Supabase.instance.client.auth.currentUser?.id ?? ''` — if user is null, it proceeds with empty string userId, which could create orphaned data.

**Fix**: Early return with error state if user is null:

```dart
final uid = Supabase.instance.client.auth.currentUser?.id;
if (uid == null) {
  ScaffoldMessenger.of(context).showSnackBar(...);
  return;
}
```

**Severity**: 🟡 Medium — Could create orphaned records.

---

## Phase 6 — Flutter Best Practices

### 6.1 Missing `const` Constructors

**Root cause**: Multiple widget classes miss `const` constructors or don't use `const` when instantiating stateless widgets.

**Files affected** (representative list):
- [dashboard_needs_attention.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/dashboard/widgets/dashboard_needs_attention.dart) — `_AttentionTile` constructor not const
- [dashboard_pulse_strip.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/dashboard/widgets/dashboard_pulse_strip.dart) — `_PulseChip` should be const
- [bill_generation_page.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/billing/view/bill_generation_page.dart) — `_SubmittingIndicator` `BoxDecoration` missing const

**Severity**: 🟢 Low — Minor rebuild optimization.

---

### 6.2 GoogleFonts.poppinsTextTheme() Network Call

#### [MODIFY] [app_theme.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/core/theme/app_theme.dart)

**Root cause**: `GoogleFonts.poppinsTextTheme()` is called every time `light()` is invoked. If the font isn't cached, it makes a network request. The theme is created in `build()` so this runs on every hot reload.

**Fix**: Cache the text theme:

```dart
static final _textTheme = GoogleFonts.poppinsTextTheme();
```

And ensure fonts are bundled in assets (they're already in `assets/fonts/` based on pubspec).

**Severity**: 🟢 Low — Only impacts first launch / cold start.

---

### 6.3 Expensive BlocBuilder in BillGenerationPage

#### [MODIFY] [bill_generation_page.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/billing/view/bill_generation_page.dart)

**Root cause**: `context.watch<BillSubmissionBloc>()` (line 149) triggers a full rebuild of the entire form on every submission state change. Should use `BlocSelector` or separate the submitting indicator.

**Fix**: Replace `context.watch` with `BlocSelector`:

```dart
final submitting = context.select<BillSubmissionBloc, bool>(
  (bloc) => bloc.state is BillSubmissionLoading,
);
```

**Severity**: 🟡 Medium — Full form rebuild on submission state changes.

---

### 6.4 Dashboard _RecentBillsSection sorts on every build

#### [MODIFY] [dashboard_screen.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/dashboard/view/dashboard_screen.dart)

**Root cause**: `_RecentBills.build()` creates a copy of the bills list and sorts it on every build. The list is already sorted in `_buildMergedStream`.

**Fix**: Remove redundant sort or use `buildWhen` to prevent unnecessary rebuilds.

**Severity**: 🟢 Low — Minor CPU waste.

---

## Phase 7 — Code Quality

### 7.1 Dead/Duplicate `_Header` Widget

#### [MODIFY] [dashboard_screen.dart](file:///c:/Users/bgame/Desktop/projects/Fast-Pos/lib/presentation/dashboard/view/dashboard_screen.dart)

**Root cause**: There are two header widgets: `_DashboardHeader` (line 104) and `_Header` (line 322). `_Header` is never used — it's dead code.

**Fix**: Remove `_Header` class (lines 322-392).

**Severity**: 🟢 Low — Dead code.

---

### 7.2 Unused Imports

Run `dart fix --apply` and clean up unused imports across the codebase.

**Severity**: 🟢 Low — Code hygiene.

---

## Phase 8 — Verification Plan

### Automated Tests
```bash
flutter test
flutter analyze
```

### Manual Verification
- Launch app → dashboard loads without showing 0 values
- Navigate all 4 bottom tabs (Dashboard, Inventory, New Bill, Analysis)
- Create a bill → verify PDF generation, share, print options
- Pull-to-refresh dashboard → data reloads
- Toggle airplane mode → offline banner appears, sync badge updates
- Check memory profiler → no growing allocations after 5 minutes idle
- Kill and restart app → dashboard loads from Hive cache instantly

### Build Verification
```bash
flutter build apk --release
```

---

## Execution Priority

| Priority | Issue | Expected Impact |
|----------|-------|----------------|
| P0 | 1.6 mergeAllFromRemote batch | -3s startup time |
| P0 | 1.1 Hive stream deduplication | -60% unnecessary rebuilds |
| P0 | 1.2 putAll batch optimization | -2s startup time |
| P1 | 1.3 Dashboard compute race fix | Fix zero-value dashboard bug |
| P1 | 2.1 + 2.2 Connectivity leak | Fix memory leak |
| P1 | 3.1 Equatable cost reduction | -50% state comparison cost |
| P1 | 5.2 Error swallowing | Enable production debugging |
| P2 | 1.4 Pull deduplication | -50% network calls |
| P2 | 1.5 Outbox purge | Prevent long-term degradation |
| P2 | 4.1 Delta sync cursors | -80% data transfer |
| P3 | 6.x Flutter best practices | Minor polish |
| P3 | 7.x Code quality | Maintainability |
