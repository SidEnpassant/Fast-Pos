import 'dart:convert';
import 'dart:io';

import 'package:inventopos/data/local/hive/hive_bill_dao.dart';
import 'package:inventopos/data/local/hive/hive_product_dao.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:path_provider/path_provider.dart';

class ExportRepositoryImpl {
  ExportRepositoryImpl({
    HiveBillDao? bills,
    HiveProductDao? products,
  })  : _bills = bills ?? HiveBillDao(),
        _products = products ?? HiveProductDao();

  final HiveBillDao _bills;
  final HiveProductDao _products;

  Future<String> exportTransactionsCsv(String userId) async {
    final bills = _bills.listForUser(userId);
    final rows = <List<dynamic>>[
      ['Date', 'Customer', 'Total', 'Paid', 'Status', 'Method'],
    ];
    for (final b in bills) {
      rows.add([
        b.createdAt.toIso8601String(),
        b.customerName,
        b.totalAmount,
        b.paidAmount,
        b.paymentStatus,
        b.paymentMethod,
      ]);
    }
    return _writeFile('transactions_export.csv', _toCsv(rows));
  }

  Future<String> exportInventoryCsv(String userId) async {
    final products = _products.listForUser(userId);
    final rows = <List<dynamic>>[
      ['Name', 'SKU', 'Barcode', 'Price', 'Stock', 'Min Threshold'],
    ];
    for (final p in products) {
      rows.add([
        p.name,
        p.sku ?? '',
        p.barcode ?? '',
        p.price,
        p.stockQuantity,
        p.minStockThreshold,
      ]);
    }
    return _writeFile('inventory_export.csv', _toCsv(rows));
  }

  Future<String> exportTransactionsJson(String userId) async {
    final bills = _bills.listForUser(userId);
    final json = jsonEncode(bills.map(_billToJson).toList());
    return _writeFile('transactions_export.json', json);
  }

  Map<String, dynamic> _billToJson(Bill b) => {
        'id': b.id,
        'customerName': b.customerName,
        'totalAmount': b.totalAmount,
        'paidAmount': b.paidAmount,
        'paymentStatus': b.paymentStatus,
        'createdAt': b.createdAt.toIso8601String(),
      };

  String _toCsv(List<List<dynamic>> rows) {
    return rows
        .map((r) =>
            r.map((c) => '"${c.toString().replaceAll('"', '""')}"').join(','))
        .join('\n');
  }

  Future<String> _writeFile(String name, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file.path;
  }
}
