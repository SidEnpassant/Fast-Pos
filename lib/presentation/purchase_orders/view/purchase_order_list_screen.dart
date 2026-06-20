import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/domain/entities/purchase_order.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_bloc.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_event.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class PurchaseOrderListScreen extends StatelessWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    
    return BlocProvider(
      create: (context) => PurchaseOrderBloc(
        context.read(),
        context.read(),
      )..add(PurchaseOrdersStarted(userId)),
      child: const PurchaseOrderListView(),
    );
  }
}

class PurchaseOrderListView extends StatefulWidget {
  const PurchaseOrderListView({super.key});

  @override
  State<PurchaseOrderListView> createState() => _PurchaseOrderListViewState();
}

class _PurchaseOrderListViewState extends State<PurchaseOrderListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Pending', 'Received', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppScreenScaffold(
      title: 'Purchase Orders',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/purchase-orders/editor'),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New PO'),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerLowest,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: theme.colorScheme.outlineVariant.withOpacity(0.5),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),
          Expanded(
            child: BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    return _buildTabContent(context, state, tab);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, PurchaseOrderState state, String tabFilter) {
    if (state.status == PurchaseOrderStatus.loading && state.orders.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: 4,
        itemBuilder: (context, index) => _buildShimmerCard(context),
      );
    }

    List<PurchaseOrder> filteredOrders = state.orders;
    if (tabFilter != 'All') {
      filteredOrders = state.orders.where((po) {
        if (tabFilter == 'Pending') return po.status.toUpperCase() == 'PENDING';
        if (tabFilter == 'Received') return po.status.toUpperCase() == 'RECEIVED';
        if (tabFilter == 'Cancelled') return po.status.toUpperCase() == 'CANCELLED';
        return true;
      }).toList();
    }

    if (filteredOrders.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: tabFilter == 'All' ? 'No Purchase Orders' : 'No $tabFilter Orders',
        message: tabFilter == 'All' 
          ? 'Create a purchase order to track incoming stock from suppliers.'
          : 'You do not have any orders matching this status.',
        actionLabel: tabFilter == 'All' ? 'Create First PO' : null,
        onAction: tabFilter == 'All' ? () => context.push('/purchase-orders/editor') : null,
      ).animate().fadeIn(duration: 400.ms);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final po = filteredOrders[index];
        return _PurchaseOrderCard(po: po)
           .animate()
           .fadeIn(delay: Duration(milliseconds: 50 * index.clamp(0, 10)))
           .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainerLowest,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder po;

  const _PurchaseOrderCard({required this.po});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    final isPending = po.status.toUpperCase() == 'PENDING';
    final isReceived = po.status.toUpperCase() == 'RECEIVED';
    final isCancelled = po.status.toUpperCase() == 'CANCELLED';

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
        onTap: () {
          if (isPending) {
            context.push('/purchase-orders/editor/${po.id}');
          } else {
            context.push('/purchase-orders/receive/${po.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.local_shipping, color: scheme.onPrimaryContainer, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                po.supplierName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PO #${po.id.substring(0, 6).toUpperCase()} • ${DateFormat('dd MMM yyyy').format(po.orderDate)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(theme, isPending, isReceived, isCancelled),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Amount', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat.currency(symbol: '₹').format(po.totalAmount),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (po.receivedDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Received On', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy').format(po.receivedDate!),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  else
                     Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Items', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(
                          '${po.lineItems.length} Items',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PO PDF...')));
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Send PDF'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                           context.push('/purchase-orders/receive/${po.id}');
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Receive'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, bool isPending, bool isReceived, bool isCancelled) {
    Color bgColor = Colors.grey.withOpacity(0.1);
    Color textColor = Colors.grey.shade700;
    String label = po.status;

    if (isPending) {
      bgColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange.shade800;
      label = 'Pending';
    } else if (isReceived) {
      bgColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green.shade700;
      label = 'Received';
    } else if (isCancelled) {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red.shade700;
      label = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
