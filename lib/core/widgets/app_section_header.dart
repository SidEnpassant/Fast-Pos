import 'package:flutter/material.dart';

/// Section title using [ThemeData.textTheme.titleMedium].
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {super.key, this.padding});

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(title, style: style),
    );
  }
}
