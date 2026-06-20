import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';

/// A skeleton for a standard list tile (icon/leading + two lines of text).
class AppListTileSkeleton extends StatelessWidget {
  const AppListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const AppSkeletonCircle(size: 48),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeletonText(width: 150),
                  SizedBox(height: AppSpacing.xs),
                  const AppSkeletonText(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A skeleton for a dashboard KPI metric card.
class AppMetricCardSkeleton extends StatelessWidget {
  const AppMetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSkeletonText(width: 80, height: 12),
              SizedBox(height: AppSpacing.sm),
              const AppSkeletonText(width: 120, height: 24),
              SizedBox(height: AppSpacing.sm),
              const AppSkeletonText(width: 60, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton for a product grid item.
class AppProductGridSkeleton extends StatelessWidget {
  const AppProductGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: AppSkeleton(borderRadius: 12),
          ),
          SizedBox(height: AppSpacing.sm),
          const AppSkeletonText(width: 100),
          SizedBox(height: AppSpacing.xs),
          const AppSkeletonText(width: 60, height: 12),
        ],
      ),
    );
  }
}

/// A list of skeletons to fill a screen.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 10,
    this.itemBuilder,
  });

  final int itemCount;
  final Widget? Function(BuildContext, int)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder:
          itemBuilder ?? (context, index) => const AppListTileSkeleton(),
    );
  }
}
