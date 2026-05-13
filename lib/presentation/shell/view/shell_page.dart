import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/responsive/app_breakpoints.dart';

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

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.dashboard_customize_outlined),
      selectedIcon: Icon(Icons.dashboard_customize),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Analysis',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_outlined),
      selectedIcon: Icon(Icons.receipt),
      label: 'New Bill',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_none_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: 'Notifications',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_2_outlined),
      selectedIcon: Icon(Icons.person_2),
      label: 'Profile',
    ),
  ];

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
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_customize_outlined),
                  selectedIcon: Icon(Icons.dashboard_customize),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('Analysis'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_outlined),
                  selectedIcon: Icon(Icons.receipt),
                  label: Text('New Bill'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.notifications_none_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: Text('Notifications'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_2_outlined),
                  selectedIcon: Icon(Icons.person_2),
                  label: Text('Profile'),
                ),
              ],
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
        destinations: _destinations,
      ),
    );
  }
}
