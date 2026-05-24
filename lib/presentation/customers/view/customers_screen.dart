import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers & Credit'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              hintText: 'Search name or phone',
              onChanged: (q) => setState(() => _query = q.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Customer>>(
        stream: context.read<CustomerRepository>().watchCustomersForUser(uid),
        builder: (context, snap) {
          var list = snap.data ?? [];
          if (_query.isNotEmpty) {
            list = list.where((c) {
              return c.name.toLowerCase().contains(_query) ||
                  (c.phone ?? '').toLowerCase().contains(_query);
            }).toList();
          }
          list = List<Customer>.from(list)
            ..sort((a, b) => b.creditBalance.compareTo(a.creditBalance));

          if (list.isEmpty) {
            return AppEmptyState(
              icon: Icons.people_outline,
              title: 'No customers yet',
              message:
                  'Customers are created automatically when you generate bills with name and phone.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              final initial = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(initial)),
                  title: Text(c.name),
                  subtitle: Text(c.phone ?? 'No phone'),
                  trailing: c.creditBalance > 0
                      ? Chip(
                          label: Text('₹${c.creditBalance.toStringAsFixed(0)}'),
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                        )
                      : (c.loyaltyPoints > 0
                          ? Chip(label: Text('${c.loyaltyPoints} pts'))
                          : null),
                  onTap: () => context.push('/customers/${c.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
