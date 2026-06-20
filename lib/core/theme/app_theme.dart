import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/core/design/app_radii.dart';

abstract final class AppTheme {
  static const Color _seedBlue = Color(0xFF2962FF);

  static ThemeData light() {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: baseTextTheme.displayLarge!.fontSize?.sp),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: baseTextTheme.displayMedium!.fontSize?.sp),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontSize: baseTextTheme.displaySmall!.fontSize?.sp),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: baseTextTheme.headlineLarge!.fontSize?.sp),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: baseTextTheme.headlineMedium!.fontSize?.sp),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: baseTextTheme.headlineSmall!.fontSize?.sp),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: baseTextTheme.titleLarge!.fontSize?.sp),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: baseTextTheme.titleMedium!.fontSize?.sp),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: baseTextTheme.titleSmall!.fontSize?.sp),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: baseTextTheme.bodyLarge!.fontSize?.sp),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: baseTextTheme.bodyMedium!.fontSize?.sp),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: baseTextTheme.bodySmall!.fontSize?.sp),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: baseTextTheme.labelLarge!.fontSize?.sp),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: baseTextTheme.labelMedium!.fontSize?.sp),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: baseTextTheme.labelSmall!.fontSize?.sp),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedBlue,
      brightness: Brightness.light,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: shape,
        color: colorScheme.surfaceContainerLow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64.w, 48.h),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(shape: shape),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(shape)),
      ),
    );
  }
}
