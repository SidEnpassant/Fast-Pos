import 'package:flutter/material.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';

class AnalyticsShimmerPlaceholder extends StatelessWidget {
  const AnalyticsShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: AppSkeleton(height: 50),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: AppSkeleton(height: 200, borderRadius: 12),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: AppSkeleton(height: 150, borderRadius: 12),
          ),
        ],
      ),
    );
  }
}
