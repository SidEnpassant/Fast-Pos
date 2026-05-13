import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/responsive/app_breakpoints.dart';
import 'package:inventopos/presentation/auth/cubit/auth_cubit.dart';
import 'package:inventopos/presentation/dashboard/cubit/dashboard_cubit.dart';
import 'package:inventopos/presentation/dashboard/cubit/dashboard_state.dart';
import 'package:inventopos/supabase_mappers.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      child: SafeArea(
        child: Column(
          children: [
            const _DashboardHeaderBar(),
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
                            style: GoogleFonts.poppins(
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
                    BlocBuilder<DashboardCubit, DashboardState>(
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

class _DashboardHeaderBar extends StatelessWidget {
  const _DashboardHeaderBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.store, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                final rows = state.profileRows;
                if (rows == null || rows.isEmpty) {
                  return const Text('Loading...');
                }
                final data = SupabaseMappers.profileFromRow(rows.first);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['businessName']?.toString() ?? 'Your Business',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}

class _StatisticsCards extends StatelessWidget {
  const _StatisticsCards({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final rows = state.billsRows;
    if (rows == null) {
      return const Center(child: CircularProgressIndicator());
    }

    double totalRevenue = 0;
    int completedTransactions = 0;
    int pendingTransactions = 0;

    for (final row in rows) {
      final data = SupabaseMappers.billFromRow(row);

      if (data['paymentStatus'] == 'complete') {
        totalRevenue += (data['totalAmount'] ?? 0).toDouble();
        completedTransactions++;
      } else if (data['paymentStatus'] == 'partial') {
        totalRevenue += (data['paidAmount'] ?? 0).toDouble();
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
          '${rows.length}',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
              color: Colors.grey[600],
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
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
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
    final streamRows = state.billsRows;
    if (streamRows == null) {
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
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Builder(
          builder: (context) {
            if (streamRows.isEmpty) {
              return const Center(
                child: Text(
                  'No bills found',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final rows = List<Map<String, dynamic>>.from(streamRows);
            rows.sort(
              (a, b) => SupabaseMappers.parseDate(b['created_at']).compareTo(
                SupabaseMappers.parseDate(a['created_at']),
              ),
            );
            final recent = rows.take(5).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              itemBuilder: (context, index) {
                final data = SupabaseMappers.billFromRow(recent[index]);
                if (!_isValidBillData(data)) {
                  return const SizedBox.shrink();
                }
                return _TransactionRow(data: data);
              },
            );
          },
        ),
      ],
    );
  }

  bool _isValidBillData(Map<String, dynamic> data) {
    return data.containsKey('customerName') &&
        data.containsKey('totalAmount') &&
        data.containsKey('paidAmount') &&
        data.containsKey('paymentStatus');
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final customerName = data['customerName'] ?? 'Unknown Customer';
    final totalAmount = data['totalAmount']?.toString() ?? '0.00';
    final paidAmount = data['paidAmount']?.toString() ?? '0.00';
    final paymentStatus = data['paymentStatus'] ?? 'Unknown';

    Color statusColor = Colors.grey;
    if (paymentStatus.toLowerCase() == 'paid') {
      statusColor = Colors.green;
    } else if (paymentStatus.toLowerCase() == 'partial') {
      statusColor = Colors.orange;
    } else if (paymentStatus.toLowerCase() == 'unpaid') {
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
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
