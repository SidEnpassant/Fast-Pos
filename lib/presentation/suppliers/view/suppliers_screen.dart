import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/domain/entities/supplier.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/suppliers/bloc/suppliers_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<SuppliersBloc>().add(SuppliersStarted(uid));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: BlocBuilder<SuppliersBloc, SuppliersState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: scheme.surfaceContainerLowest,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'Suppliers & Khata',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: () {
                       // Action to sort by Most Recent, Name, Balance
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Sorting options coming soon!'))
                       );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppMetricCard.heightCompact,
                          child: AppMetricCard(
                            title: 'Total Suppliers',
                            value: '${state.allSuppliers.length}',
                            icon: Icons.business,
                            color: Colors.blue,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: AppMetricCard.heightCompact,
                          child: AppMetricCard(
                            title: 'To Pay',
                            value: '₹0.00', // Mocked ledger balance
                            icon: Icons.account_balance_wallet,
                            color: Colors.orange,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search suppliers or phone numbers',
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.search),
                    ),
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(
                      scheme.surfaceContainerLow,
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onChanged: (q) => context
                        .read<SuppliersBloc>()
                        .add(SuppliersSearchQueryChanged(q)),
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ),
              if (state.loading && state.allSuppliers.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(context),
                    childCount: 5,
                  ),
                )
              else if (state.filteredSuppliers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.store_outlined,
                    title: 'No suppliers found',
                    message: state.searchQuery.isEmpty 
                      ? 'Add your first supplier to manage purchase orders and ledger balances.'
                      : 'No suppliers match your search query.',
                    actionLabel: state.searchQuery.isEmpty ? 'Add supplier' : null,
                    onAction: state.searchQuery.isEmpty 
                      ? () => context.push('/suppliers/editor')
                      : null,
                  ).animate().fadeIn(duration: 400.ms),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final supplier = state.filteredSuppliers[i];
                        return _SupplierCard(supplier: supplier)
                           .animate()
                           .fadeIn(delay: Duration(milliseconds: 50 * i.clamp(0, 10)))
                           .slideY(begin: 0.1, end: 0);
                      },
                      childCount: state.filteredSuppliers.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/suppliers/editor'),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Supplier'),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainerLowest,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;

  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    final avatarText = supplier.name.isNotEmpty 
      ? supplier.name.substring(0, 1).toUpperCase() 
      : '?';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/suppliers/editor', extra: supplier.id),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      avatarText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                supplier.phone!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ] else if (supplier.email != null && supplier.email!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email, size: 12, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                supplier.email!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ledger: ₹0', // Mock representation of packed features
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.5)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    color: Colors.blue,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Calling...'))
                       );
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.chat_outlined, // Fallback for WhatsApp icon
                    label: 'WhatsApp',
                    color: Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Opening WhatsApp...'))
                       );
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.assignment_outlined,
                    label: 'View POs',
                    color: scheme.primary,
                    onTap: () {
                      context.push('/purchase-orders');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
