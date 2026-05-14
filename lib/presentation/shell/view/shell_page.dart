import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/responsive/app_breakpoints.dart';
import 'package:inventopos/presentation/shell/widgets/shell_navigation_config.dart';

/// Signed-in root: adaptive [NavigationBar] / [NavigationRail] around
/// [StatefulNavigationShell] from [go_router].
class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return _ShellScaffold(navigationShell: navigationShell);
  }
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final useRail = AppBreakpoints.isMediumOrWider(context);

    void onSelect(int i) => navigationShell.goBranch(i);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: ShellNavigationConfig.railDestinations,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: ShellNavigationConfig.barDestinations,
      ),
    );
  }
}
