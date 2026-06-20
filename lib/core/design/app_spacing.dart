import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing scale (logical pixels) for padding and gaps.
abstract final class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
}
