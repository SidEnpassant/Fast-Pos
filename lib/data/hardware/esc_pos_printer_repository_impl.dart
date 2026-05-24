import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/receipt_payload.dart';
import 'package:inventopos/domain/repositories/printer_repository.dart';

class EscPosPrinterRepositoryImpl implements PrinterRepository {
  Box<Map> get _box => Hive.box<Map>(HiveBoxes.printers);

  @override
  Stream<List<Map<String, dynamic>>> scanDevices() async* {
    final devices = <Map<String, dynamic>>[];
    await for (final state in FlutterBluePlus.scanResults) {
      for (final r in state) {
        devices.add({
          'name': r.device.platformName.isNotEmpty
              ? r.device.platformName
              : 'Unknown',
          'mac': r.device.remoteId.str,
        });
      }
      yield devices;
    }
  }

  Future<void> startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
  }

  @override
  Future<void> saveDefaultPrinter({
    required String userId,
    required String macAddress,
    required String name,
    required int paperWidthMm,
  }) async {
    for (final key in _box.keys) {
      final m = Map<String, dynamic>.from(_box.get(key)!);
      if (m['user_id'] == userId) {
        m['is_default'] = false;
        await _box.put(key, m);
      }
    }
    await _box.put('$userId:$macAddress', {
      'user_id': userId,
      'mac_address': macAddress,
      'name': name,
      'paper_width_mm': paperWidthMm,
      'is_default': true,
    });
  }

  @override
  Future<Map<String, dynamic>?> getDefaultPrinter(String userId) async {
    for (final raw in _box.values) {
      final m = Map<String, dynamic>.from(raw);
      if (m['user_id'] == userId && m['is_default'] == true) return m;
    }
    return null;
  }

  @override
  Future<void> printReceipt(ReceiptPayload payload) async {
    final printer = await getDefaultPrinter('');
    final width = (printer?['paper_width_mm'] as int?) ?? 58;
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      width == 80 ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );
    final bytes = <int>[];
    bytes.addAll(generator.text(payload.businessName,
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    if (payload.billNumber != null) {
      bytes.addAll(generator.text('Bill #${payload.billNumber}',
          styles: const PosStyles(align: PosAlign.center)));
    }
    bytes.addAll(generator.text('Customer: ${payload.customerName}'));
    bytes.addAll(generator.hr());
    for (final line in payload.lines) {
      bytes.addAll(generator.row([
        PosColumn(
          text: line.name,
          width: 8,
        ),
        PosColumn(
          text: '${line.quantity}',
          width: 2,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: line.total.toStringAsFixed(2),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
      'TOTAL: ${payload.totalAmount.toStringAsFixed(2)}',
      styles: const PosStyles(bold: true, align: PosAlign.right),
    ));
    bytes.addAll(generator.text('Paid: ${payload.paidAmount.toStringAsFixed(2)}'));
    bytes.addAll(generator.text('Via: ${payload.paymentMethod}'));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    final mac = printer?['mac_address'] as String?;
    if (mac == null) return;

    final device = BluetoothDevice.fromId(mac);
    await device.connect(timeout: const Duration(seconds: 10));
    final services = await device.discoverServices();
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.properties.writeWithoutResponse || c.properties.write) {
          await c.write(bytes, withoutResponse: true);
          break;
        }
      }
    }
    await device.disconnect();
  }
}
