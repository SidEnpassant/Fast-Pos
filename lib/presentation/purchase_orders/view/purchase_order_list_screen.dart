import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_bloc.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_event.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseOrderListScreen extends StatelessWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    
    return BlocProvider(
      create: (context) => PurchaseOrderBloc(context.read())
        ..add(PurchaseOrdersStarted(userId)),
      child: const PurchaseOrderListView(),
    );
  }
}

class PurchaseOrderListView extends StatelessWidget {
  const PurchaseOrderListView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Purchase Orders',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/purchase-orders/editor'),
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
      ),
      body: BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
        builder: (context, state) {
          if (state.status == PurchaseOrderStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.orders.isEmpty) {
            return const Center(child: Text('No purchase orders found'));
          }
          return ListView.builder(
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final po = state.orders[index];
              return ListTile(
                title: Text(po.supplierName),
                subtitle: Text('Status: ${po.status} • ${DateFormat.yMMMd().format(po.orderDate)}'),
                trailing: Text(
                  NumberFormat.currency(symbol: '₹').format(po.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () {
                  if (po.status == 'PENDING') {
                    context.push('/purchase-orders/editor', extra: po.id);
                  } else {
                    context.push('/purchase-orders/receive', extra: po.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
