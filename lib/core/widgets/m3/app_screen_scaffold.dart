import 'package:flutter/material.dart';

/// Shared M3 screen wrapper aligned with dashboard styling.
class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.leading,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        actions: actions,
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
