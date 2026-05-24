import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/data/export/export_repository_impl.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/presentation/import_export/bloc/import_inventory_bloc.dart';
import 'package:share_plus/share_plus.dart';

class ImportExportPage extends StatelessWidget {
  const ImportExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthRepository>().currentSession?.userId ?? '';
    return BlocProvider(
      create: (c) => ImportInventoryBloc(c.read<ProductRepository>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Import / Export')),
        body: BlocBuilder<ImportInventoryBloc, ImportInventoryState>(
          builder: (context, importState) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (importState.importing) ...[
                  LinearProgressIndicator(
                    value: importState.total > 0
                        ? importState.progress / importState.total
                        : null,
                  ),
                  const SizedBox(height: 8),
                  const Text('Importing products…'),
                  const SizedBox(height: 16),
                ],
                if (importState.message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(importState.message!),
                  ),
                if (importState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      importState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: importState.importing
                      ? null
                      : () => _importCsv(context, uid),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import inventory (CSV/XLSX)'),
                ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final path = await context
                  .read<ExportRepositoryImpl>()
                  .exportInventoryCsv(uid);
              await Share.shareXFiles([XFile(path)]);
            },
            icon: const Icon(Icons.download),
            label: const Text('Export inventory CSV'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final path = await context
                  .read<ExportRepositoryImpl>()
                  .exportTransactionsCsv(uid);
              await Share.shareXFiles([XFile(path)]);
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('Export transactions CSV'),
          ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _importCsv(BuildContext context, String uid) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final rows = <Map<String, dynamic>>[];

    if (file.path?.endsWith('.xlsx') == true && file.bytes != null) {
      final excel = Excel.decodeBytes(file.bytes!);
      final sheet = excel.tables.values.first;
      final headers = sheet.rows.first
          .map((c) => c?.value?.toString().toLowerCase() ?? '')
          .toList();
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final m = <String, dynamic>{};
        for (var j = 0; j < headers.length; j++) {
          final cell = j < row.length ? row[j] : null;
          m[headers[j]] = cell?.value?.toString();
        }
        rows.add(_mapImportRow(m));
      }
    } else if (file.bytes != null) {
      final text = utf8.decode(file.bytes!);
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
      final parsed = lines.map((l) => l.split(',')).toList();
      if (parsed.isEmpty) return;
      final headers =
          parsed.first.map((e) => e.toLowerCase().replaceAll('"', '')).toList();
      for (var i = 1; i < parsed.length; i++) {
        final m = <String, dynamic>{};
        for (var j = 0; j < headers.length && j < parsed[i].length; j++) {
          m[headers[j]] = parsed[i][j].replaceAll('"', '');
        }
        rows.add(_mapImportRow(m));
      }
    }

    context.read<ImportInventoryBloc>().add(ImportInventoryStarted(uid, rows));
  }

  Map<String, dynamic> _mapImportRow(Map<String, dynamic> m) => {
        'name': m['name']?.toString() ?? '',
        'barcode': m['barcode']?.toString(),
        'sku': m['sku']?.toString(),
        'price': double.tryParse(m['price']?.toString() ?? '0') ?? 0,
        'stock_quantity': int.tryParse(m['stock']?.toString() ?? '0') ?? 0,
        'min_stock_threshold':
            int.tryParse(m['min_stock_threshold']?.toString() ?? '5') ?? 5,
      };
}
