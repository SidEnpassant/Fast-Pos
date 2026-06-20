import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';

class CustomerDetailSkeleton extends StatelessWidget {
  const CustomerDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: const Row(
                children: [
                  AppSkeletonCircle(size: 56),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonText(width: 150, height: 20),
                      SizedBox(height: 8),
                      AppSkeletonText(width: 100, height: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: AppMetricCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: AppMetricCardSkeleton()),
            ],
          ),
          const SizedBox(height: 12),
          const AppSkeletonText(width: 100, height: 20),
          const SizedBox(height: 12),
          const AppSkeletonList(itemCount: 5),
        ],
      ),
    );
  }
}
