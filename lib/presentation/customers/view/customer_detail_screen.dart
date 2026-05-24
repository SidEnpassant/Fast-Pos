import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Map>(HiveBoxes.customers).listenable(),
        builder: (context, box, _) {
          final raw = box.get(customerId);
          if (raw == null) {
            return const Center(child: Text('Customer not found'));
          }
          final m = Map<String, dynamic>.from(raw);
          final customer = Customer(
            id: m['id'] as String,
            userId: m['user_id'] as String,
            name: m['name'] as String,
            phone: m['phone'] as String?,
            creditBalance: (m['credit_balance'] as num?)?.toDouble() ?? 0,
            loyaltyPoints: (m['loyalty_points'] as num?)?.toInt() ?? 0,
            updatedAt: DateTime.parse(m['updated_at'] as String),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(
                  customer.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                subtitle: Text(customer.phone ?? 'No phone'),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                title: 'Credit balance',
                child: Text(
                  '₹${customer.creditBalance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: customer.creditBalance > 0
                            ? Theme.of(context).colorScheme.error
                            : null,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (customer.creditBalance > 0) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _recordPayment(context, customer),
                  icon: const Icon(Icons.payments),
                  label: const Text('Record payment'),
                ),
              ],
              const SizedBox(height: 16),
              const AppSectionCard(
                title: 'Ledger',
                child: Text(
                  'Ledger entries sync from Supabase when online. '
                  'Recent debits are recorded when bills use credit or partial payment.',
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                title: 'Loyalty',
                child: Text('${customer.loyaltyPoints} points'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _recordPayment(BuildContext context, Customer customer) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record payment'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text) ?? 0;
              if (v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (amount == null || !context.mounted) return;
    await context.read<CustomerRepository>().recordCreditPayment(
          customerId: customer.id,
          amount: amount,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded')),
      );
    }
  }
}
