import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/application/customers/phone_normalizer.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthRepository>().currentSession?.userId ?? '';
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: 'Customers',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: Column(
        children: [
          StreamBuilder<List<Customer>>(
            stream:
                context.read<CustomerRepository>().watchCustomersForUser(uid),
            builder: (context, snap) {
              final all = snap.data ?? [];
              final withPhone =
                  all.where((c) => (c.phone ?? '').trim().isNotEmpty).length;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppMetricCard.heightCompact,
                        child: AppMetricCard(
                          title: 'Total customers',
                          value: '${all.length}',
                          icon: Icons.people,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: AppMetricCard.heightCompact,
                        child: AppMetricCard(
                          title: 'With phone',
                          value: '$withPhone',
                          icon: Icons.phone,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              hintText: 'Search name or phone',
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                scheme.surfaceContainerLow,
              ),
              onChanged: (q) => setState(() => _query = q.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: context
                  .read<CustomerRepository>()
                  .watchCustomersForUser(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var list = snap.data ?? [];
                if (_query.isNotEmpty) {
                  final normalizedQuery = PhoneNormalizer.normalize(_query);
                  list = list.where((c) {
                    final phone = (c.phone ?? '').toLowerCase();
                    final phoneNorm = PhoneNormalizer.normalize(phone);
                    return c.name.toLowerCase().contains(_query) ||
                        phone.contains(_query) ||
                        (normalizedQuery.isNotEmpty &&
                            phoneNorm.contains(normalizedQuery));
                  }).toList();
                }
                list = List<Customer>.from(list)
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                if (list.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No customers yet',
                    message:
                        'Customers are created when you generate bills with name and phone.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return _CustomerCard(
                      customer: c,
                      onTap: () => context.push('/customers/${c.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(initial),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone ?? 'No phone',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
