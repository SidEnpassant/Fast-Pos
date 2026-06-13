import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/responsive/app_breakpoints.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cross = AppBreakpoints.gridCrossAxisCount(context);
    
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonText(width: 100, height: 14),
                      SizedBox(height: 8),
                      AppSkeletonText(width: 200, height: 24),
                      SizedBox(height: 8),
                      AppSkeletonText(width: 120, height: 14),
                    ],
                  ),
                ),
                AppSkeletonCircle(size: 40),
                const SizedBox(width: 8),
                AppSkeletonCircle(size: 40),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // KPI Grid Skeleton
              if (cross == 2)
                const Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: AppMetricCardSkeleton()),
                        SizedBox(width: 12),
                        Expanded(child: AppMetricCardSkeleton()),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: AppMetricCardSkeleton()),
                        SizedBox(width: 12),
                        Expanded(child: AppMetricCardSkeleton()),
                      ],
                    ),
                  ],
                )
              else
                GridView.count(
                  crossAxisCount: cross,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.12,
                  children: List.generate(4, (_) => const AppMetricCardSkeleton()),
                ),
              
              const SizedBox(height: AppSpacing.md),
              // Pulse Strip Skeleton
              const AppShimmer(
                child: AppSkeleton(height: 80, borderRadius: 12),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Quick Actions Skeleton
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: List.generate(8, (_) => const AppSkeletonCircle(size: 56)),
              ),
              const SizedBox(height: AppSpacing.lg),
              // AI Briefing Skeleton
              const AppShimmer(
                child: AppSkeleton(height: 150, borderRadius: 16),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Recent Bills Skeleton
              const AppSkeletonText(width: 120, height: 20),
              const SizedBox(height: AppSpacing.md),
              const AppSkeletonList(itemCount: 5),
            ]),
          ),
        ),
      ],
    );
  }
}
