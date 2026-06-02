import 'package:flutter/material.dart';

/// Shared M3 screen wrapper aligned with dashboard styling.
class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.leading,
  }) : assert(title != null || titleWidget != null);

  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: titleWidget ?? Text(title!),
        leading: leading,
        actions: actions,
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
    );
  }
}
