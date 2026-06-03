import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom / rail tab indices for [StatefulShellRoute.indexedStack].
enum AppShellBranch {
  dashboard,
  inventory,
  newBill,
  analysis,
}

extension AppShellBranchX on AppShellBranch {
  int get index => switch (this) {
        AppShellBranch.dashboard => 0,
        AppShellBranch.inventory => 1,
        AppShellBranch.newBill => 2,
        AppShellBranch.analysis => 3,
      };

  String get path => switch (this) {
        AppShellBranch.dashboard => '/app/dashboard',
        AppShellBranch.inventory => '/app/inventory',
        AppShellBranch.newBill => '/app/new-bill',
        AppShellBranch.analysis => '/app/analysis',
      };
}

/// Analytics suite [TabBar] segments (query `tab` on `/app/analysis`).
enum AnalyticsSuiteTab {
  overview,
  revenue,
  pnl,
  inventory,
  customers,
}

extension AnalyticsSuiteTabX on AnalyticsSuiteTab {
  String get queryValue => name;

  int get tabIndex => switch (this) {
        AnalyticsSuiteTab.overview => 0,
        AnalyticsSuiteTab.revenue => 1,
        AnalyticsSuiteTab.pnl => 2,
        AnalyticsSuiteTab.inventory => 3,
        AnalyticsSuiteTab.customers => 4,
      };
}

/// Switches the signed-in shell to [branch] (preferred over raw `context.go`).
void goAppShellBranch(BuildContext context, AppShellBranch branch) {
  final shell = StatefulNavigationShell.maybeOf(context);
  if (shell != null) {
    shell.goBranch(branch.index);
    return;
  }
  context.go(branch.path);
}

/// Opens a full-screen route registered on [appRootNavigatorKey].
void pushAppRootRoute(BuildContext context, String location) {
  GoRouter.of(context).push(location);
}

/// Opens Analytics on the shell and selects [tab] when provided.
void goAppAnalytics(
  BuildContext context, {
  AnalyticsSuiteTab tab = AnalyticsSuiteTab.overview,
}) {
  final location = '/app/analysis?tab=${tab.queryValue}';
  final shell = StatefulNavigationShell.maybeOf(context);
  if (shell != null) {
    shell.goBranch(AppShellBranch.analysis.index);
  }
  GoRouter.of(context).go(location);
}

AnalyticsSuiteTab? analyticsTabFromQuery(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final tab in AnalyticsSuiteTab.values) {
    if (tab.queryValue == value) return tab;
  }
  return null;
}

/// Reads `tab` from `/app/analysis` and returns the matching index, or null.
int? analyticsTabIndexFromRoute(GoRouterState state) {
  final tab = analyticsTabFromQuery(state.uri.queryParameters['tab']);
  return tab?.tabIndex;
}
