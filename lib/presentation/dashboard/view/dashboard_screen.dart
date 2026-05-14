import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/core/responsive/app_breakpoints.dart';
import 'package:inventopos/core/widgets/app_section_header.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_state.dart';
import 'package:inventopos/presentation/dashboard/widgets/dashboard_header_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: Column(
          children: [
            const DashboardHeaderBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dashboard',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ) ??
                                GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<DashboardBloc, DashboardState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatisticsCards(state: state),
                            const SizedBox(height: 24),
                            _QuickActions(context),
                            const SizedBox(height: 24),
                            _RecentTransactions(state: state),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsCards extends StatelessWidget {
  const _StatisticsCards({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final bills = state.bills;
    if (bills == null) {
      return const Center(child: CircularProgressIndicator());
    }

    double totalRevenue = 0;
    int completedTransactions = 0;
    int pendingTransactions = 0;

    for (final bill in bills) {
      if (bill.paymentStatus == 'complete') {
        totalRevenue += bill.totalAmount;
        completedTransactions++;
      } else if (bill.paymentStatus == 'partial') {
        totalRevenue += bill.paidAmount;
        pendingTransactions++;
      } else {
        pendingTransactions++;
      }
    }

    final crossCount = AppBreakpoints.gridCrossAxisCount(context);

    return GridView.count(
      crossAxisCount: crossCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _StatCard(
          'Total Revenue',
          '₹${totalRevenue.toStringAsFixed(2)}',
          Icons.currency_rupee,
          Colors.green,
        ),
        _StatCard(
          'Total Transactions',
          '${bills.length}',
          Icons.receipt_long,
          Colors.blue,
        ),
        _StatCard(
          'Completed',
          '$completedTransactions',
          Icons.check_circle_outline,
          Colors.purple,
        ),
        _StatCard(
          'Pending',
          '$pendingTransactions',
          Icons.pending_actions,
          Colors.orange,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions(this.contextParent);

  final BuildContext contextParent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader('Quick Actions'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                'Complete\nTransactions',
                Icons.check_circle_outline,
                Colors.green,
                () => context.push('/complete-transactions'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionButton(
                'Incomplete\nTransactions',
                Icons.pending_actions,
                Colors.orange,
                () => context.push('/incomplete-transactions'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(this.title, this.icon, this.color, this.onTap);

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bills = state.bills;
    if (bills == null) {
      return const Center(
        child: Text(
          'Please log in to view recent bills',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Bills',
          style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ) ??
              GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
        ),
        Builder(
          builder: (context) {
            if (bills.isEmpty) {
              return const Center(
                child: Text(
                  'No bills found',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final sorted = List<Bill>.from(bills)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final recent = sorted.take(5).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              itemBuilder: (context, index) {
                final bill = recent[index];
                if (!_isValidBill(bill)) {
                  return const SizedBox.shrink();
                }
                return _TransactionRow(bill: bill);
              },
            );
          },
        ),
      ],
    );
  }

  bool _isValidBill(Bill bill) {
    return bill.customerName.isNotEmpty;
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerName =
        bill.customerName.isEmpty ? 'Unknown Customer' : bill.customerName;
    final totalAmount = bill.totalAmount.toString();
    final paidAmount = bill.paidAmount.toString();
    final paymentStatus = bill.paymentStatus;

    Color statusColor = theme.colorScheme.outline;
    final pl = paymentStatus.toLowerCase();
    if (pl == 'paid' || pl == 'complete') {
      statusColor = Colors.green;
    } else if (pl == 'partial') {
      statusColor = Colors.orange;
    } else if (pl == 'unpaid') {
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Total: ₹$totalAmount',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Paid: ₹$paidAmount',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paymentStatus,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
