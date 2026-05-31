import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
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
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 120,
                      child: AppMetricCard(
                        title: 'Total spent',
                        value: '₹${state.totalSpent.toStringAsFixed(0)}',
                        icon: Icons.payments,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 120,
                      child: AppMetricCard(
                        title: 'Bills',
                        value: '${state.bills.length}',
                        icon: Icons.receipt_long,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                title: 'Bill history',
                child: state.bills.isEmpty
                    ? const Text('No bills yet for this customer')
                    : Column(
                        children: state.bills.map((bill) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              DateFormat.yMMMd().format(bill.createdAt),
                            ),
                            subtitle: Text(
                              '${bill.paymentStatus} · ₹${bill.totalAmount.toStringAsFixed(2)}',
                            ),
                            trailing: bill.pdfUrl != null
                                ? IconButton(
                                    icon: const Icon(Icons.picture_as_pdf),
                                    onPressed: () =>
                                        openBillPdf(context, bill.pdfUrl),
                                  )
                                : null,
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
