import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/application/customers/phone_normalizer.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
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
    return AppScreenScaffold(
      title: 'Customers',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              hintText: 'Search name or phone',
              onChanged: (q) => setState(() => _query = q.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream:
                  context.read<CustomerRepository>().watchCustomersForUser(uid),
              builder: (context, snap) {
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
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    final initial =
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(initial)),
                        title: Text(c.name),
                        subtitle: Text(c.phone ?? 'No phone'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/customers/${c.id}'),
                      ),
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
