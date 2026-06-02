import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/core/widgets/m3/app_status_chip.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/customers/bloc/customer_detail_bloc.dart';
import 'package:inventopos/presentation/customers/bloc/customer_detail_event.dart';
import 'package:inventopos/presentation/customers/bloc/customer_detail_state.dart';
import 'package:inventopos/presentation/transactions/widgets/bill_pdf_viewer_page.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<CustomerDetailBloc>().add(
            CustomerDetailStarted(
              userId: uid,
              customerId: widget.customerId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Customer',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: BlocBuilder<CustomerDetailBloc, CustomerDetailState>(
        builder: (context, state) {
          if (state.loading && state.customer == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final customer = state.customer;
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }

          final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          final initial =
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppSectionCard(
                title: 'Profile',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      child: Text(
                        initial,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.phone ?? 'No phone',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 128,
                      child: AppMetricCard(
                        title: 'Total spent',
                        value: fmt.format(state.totalSpent),
                        icon: Icons.payments,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 128,
                      child: AppMetricCard(
                        title: 'Bills',
                        value: '${state.bills.length}',
                        icon: Icons.receipt_long,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppSectionCard(
                title: 'Bill history',
                child: state.bills.isEmpty
                    ? Text(
                        'No bills yet for this customer',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      )
                    : Column(
                        children: state.bills.map((bill) {
                          final status = bill.paymentStatus.toLowerCase();
                          final statusColor = status == 'complete'
                              ? Colors.green.shade700
                              : status == 'partial'
                                  ? Colors.orange.shade800
                                  : Theme.of(context).colorScheme.error;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.md),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.md),
                                ),
                                title: Text(
                                  DateFormat.yMMMd().format(bill.createdAt),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      AppStatusChip(
                                        label: bill.paymentStatus,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fmt.format(bill.totalAmount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: bill.pdfUrl != null
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.picture_as_pdf_outlined,
                                        ),
                                        tooltip: 'Show bill',
                                        onPressed: () => openBillPdf(
                                          context,
                                          bill.pdfUrl,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
