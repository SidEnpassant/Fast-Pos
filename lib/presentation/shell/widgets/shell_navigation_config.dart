import 'package:flutter/material.dart';

/// Shared navigation labels/icons for [ShellPage] (bar + rail).
abstract final class ShellNavigationConfig {
  static const List<NavigationDestination> barDestinations = [
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

  static const List<NavigationRailDestination> railDestinations = [
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
  ];
}
