import 'package:flutter/material.dart';

/// Layout breakpoints aligned with Material window size classes.
abstract final class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) =>
      widthOf(context) < tablet;

  static bool isMediumOrWider(BuildContext context) =>
      widthOf(context) >= tablet;

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= desktop;

  /// Responsive grid columns for stat cards and similar.
  static int gridCrossAxisCount(
    BuildContext context, {
    int compact = 2,
    int medium = 3,
    int wide = 4,
  }) {
    final w = widthOf(context);
    if (w >= desktop) return wide;
    if (w >= tablet) return medium;
    return compact;
  }
}
