import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/application/billing/resolve_product_for_barcode_use_case.dart';
import 'package:inventopos/core/widgets/m3/app_barcode_scan_sheet.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/widgets/bill_line_quantity_sheet.dart';

Future<void> showBillAddProductChooser(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add to bill',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ChooserTile(
                      icon: Icons.qr_code_scanner,
                      label: 'Scan barcode',
                      subtitle: 'Lookup from inventory',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) _runScanFlow(context);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ChooserTile(
                      icon: Icons.inventory_2_outlined,
                      label: 'Select from inventory',
                      subtitle: 'Browse catalog',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          if (!context.mounted) return;
                          final draftLines =
                              context.read<BillDraftBloc>().state.lines;
                          final line = await context.push<BillDraftLine>(
                            '/app/bill/inventory-picker',
                            extra: draftLines,
                          );
                          if (line != null && context.mounted) {
                            context
                                .read<BillDraftBloc>()
                                .add(BillDraftLineAdded(line));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${line.name}')),
                            );
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _runScanFlow(BuildContext context) async {
  final code = await showAppBarcodeScanSheet(
    context,
    title: 'Scan product',
  );
  if (code == null || !context.mounted) return;

  final uid = context.read<AuthRepository>().currentSession?.userId;
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in to scan inventory')),
    );
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppShimmer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Product? product;
  try {
    product = await context.read<ResolveProductForBarcodeUseCase>()(
      userId: uid,
      barcode: code,
    );
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (!context.mounted) return;

  if (product == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not in inventory')),
    );
    return;
  }

  final draftLines = context.read<BillDraftBloc>().state.lines;
  final line = await showBillLineQuantitySheetForProduct(
    context,
    product,
    existingLines: draftLines,
  );

  if (line != null && context.mounted) {
    context.read<BillDraftBloc>().add(BillDraftLineAdded(line));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${product.name}')),
    );
  }
}

class _ChooserTile extends StatelessWidget {
  const _ChooserTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
