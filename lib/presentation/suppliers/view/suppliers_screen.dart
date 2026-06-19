import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/suppliers/bloc/suppliers_bloc.dart';

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
                pinned: false,
                backgroundColor: scheme.surfaceContainerLowest,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'Suppliers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
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
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search suppliers',
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(
                      scheme.surfaceContainerLow,
                    ),
                    onChanged: (q) => context
                        .read<SuppliersBloc>()
                        .add(SuppliersSearchQueryChanged(q)),
                  ),
                ),
              ),
              if (state.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.filteredSuppliers.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.business_outlined,
                    title: 'No suppliers',
                    message: state.searchQuery.isEmpty 
                      ? 'Add your first supplier to manage purchase orders'
                      : 'No suppliers match your search',
                    actionLabel: state.searchQuery.isEmpty ? 'Add supplier' : null,
                    onAction: state.searchQuery.isEmpty 
                      ? () => context.push('/suppliers/editor')
                      : null,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final supplier = state.filteredSuppliers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            supplier.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(color: scheme.onPrimaryContainer),
                          ),
                        ),
                        title: Text(supplier.name),
                        subtitle: Text(supplier.phone ?? supplier.email ?? 'No contact info'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/suppliers/editor',
                          extra: supplier.id,
                        ),
                      );
                    },
                    childCount: state.filteredSuppliers.length,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/suppliers/editor'),
        icon: const Icon(Icons.add),
        label: const Text('Supplier'),
      ),
    );
  }
}
