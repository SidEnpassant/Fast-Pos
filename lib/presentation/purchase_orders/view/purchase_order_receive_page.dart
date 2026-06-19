import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/domain/entities/purchase_order.dart';
import 'package:inventopos/domain/repositories/purchase_order_repository.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_bloc.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseOrderReceivePage extends StatefulWidget {
  final String purchaseOrderId;

  const PurchaseOrderReceivePage({super.key, required this.purchaseOrderId});

  @override
  State<PurchaseOrderReceivePage> createState() => _PurchaseOrderReceivePageState();
}

class _PurchaseOrderReceivePageState extends State<PurchaseOrderReceivePage> {
  PurchaseOrder? _po;
  List<PurchaseOrderLine> _receivedLines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPO();
  }

  Future<void> _loadPO() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final repo = context.read<PurchaseOrderRepository>();
    final orders = await repo.watchPurchaseOrdersForUser(userId).first;
    final po = orders.firstWhere((o) => o.id == widget.purchaseOrderId);
    
    setState(() {
      _po = po;
      _receivedLines = po.lineItems.map((line) => PurchaseOrderLine(
        productId: line.productId,
        productName: line.productName,
        orderedQty: line.orderedQty,
        receivedQty: line.orderedQty, // Default to receiving everything
        unitCost: line.unitCost,
        uom: line.uom,
      )).toList();
      _isLoading = false;
    });
  }

  void _confirmReceipt() {
    if (_po == null) return;
    
    context.read<PurchaseOrderBloc>().add(PurchaseOrderReceived(_po!.id, _receivedLines));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScreenScaffold(
        title: 'Receive Purchase Order',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScreenScaffold(
      title: 'Receive PO: ${_po?.id.substring(0, 8)}',
      actions: [
        TextButton(
          onPressed: _confirmReceipt,
          child: const Text('Confirm'),
        ),
      ],
      body: ListView.builder(
        itemCount: _receivedLines.length,
        itemBuilder: (context, index) {
          final line = _receivedLines[index];
          return ListTile(
            title: Text(line.productName),
            subtitle: Text('Ordered: ${line.orderedQty} ${line.uom}'),
            trailing: SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: line.receivedQty.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Received'),
                onChanged: (val) {
                  final qty = double.tryParse(val) ?? 0;
                  setState(() {
                    _receivedLines[index] = PurchaseOrderLine(
                      productId: line.productId,
                      productName: line.productName,
                      orderedQty: line.orderedQty,
                      receivedQty: qty,
                      unitCost: line.unitCost,
                      uom: line.uom,
                    );
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
