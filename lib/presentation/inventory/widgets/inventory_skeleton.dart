import 'package:flutter/material.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_state.dart';

class InventorySkeleton extends StatelessWidget {
  const InventorySkeleton({super.key, required this.viewMode});

  final InventoryViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    if (viewMode == InventoryViewMode.grid) {
      return SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => const AppProductGridSkeleton(),
            childCount: 6,
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(
      child: AppSkeletonList(itemCount: 8),
    );
  }
}
