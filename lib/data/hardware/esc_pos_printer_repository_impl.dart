import 'dart:async';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/receipt_payload.dart';
import 'package:inventopos/domain/repositories/printer_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EscPosPrinterRepositoryImpl implements PrinterRepository {
  Box<Map> get _box => Hive.box<Map>(HiveBoxes.printers);

  @override
  Stream<List<Map<String, dynamic>>> scanDevices() async* {
    final devices = <Map<String, dynamic>>[];
    await for (final state in FlutterBluePlus.scanResults) {
      devices.clear();
      for (final r in state) {
        if (r.device.platformName.isNotEmpty) {
          devices.add({
            'name': r.device.platformName,
            'mac': r.device.remoteId.str,
          });
        }
      }
      yield devices;
    }
  }

  @override
  Future<void> startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
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
  Future<void> deleteDefaultPrinter(String userId) async {
    final toDelete = <dynamic>[];
    for (final key in _box.keys) {
      final m = Map<String, dynamic>.from(_box.get(key)!);
      if (m['user_id'] == userId) {
        toDelete.add(key);
      }
    }
    for (final k in toDelete) {
      await _box.delete(k);
    }
  }

  @override
  Future<void> printReceipt(ReceiptPayload payload) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final printer = await getDefaultPrinter(userId);
    final width = (printer?['paper_width_mm'] as int?) ?? 58;
    
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      width == 80 ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );
    final bytes = <int>[];
    bytes.addAll(generator.text(payload.businessName,
        styles: const PosStyles(align: PosAlign.center, bold: true, width: PosTextSize.size2, height: PosTextSize.size2)));
    bytes.addAll(generator.feed(1));
    if (payload.billNumber != null) {
      bytes.addAll(generator.text('Bill #${payload.billNumber}',
          styles: const PosStyles(align: PosAlign.center)));
    }
    bytes.addAll(generator.text('Customer: ${payload.customerName}'));
    bytes.addAll(generator.hr());
    
    // Header
    bytes.addAll(generator.row([
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true, align: PosAlign.center)),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]));
    bytes.addAll(generator.hr());

    for (final line in payload.lines) {
      bytes.addAll(generator.row([
        PosColumn(
          text: line.name.length > 15 ? '${line.name.substring(0, 14)}.' : line.name,
          width: 6,
        ),
        PosColumn(
          text: '${line.quantity}',
          width: 2,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: line.total.toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
      'TOTAL: ${payload.totalAmount.toStringAsFixed(2)}',
      styles: const PosStyles(bold: true, align: PosAlign.right, width: PosTextSize.size2),
    ));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('Paid: ${payload.paidAmount.toStringAsFixed(2)}', styles: const PosStyles(align: PosAlign.right)));
    bytes.addAll(generator.text('Via: ${payload.paymentMethod}', styles: const PosStyles(align: PosAlign.right)));
    
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.text('Thank you for shopping!', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(2));
    
    try {
      bytes.addAll(generator.cut());
    } catch (_) {}

    final mac = printer?['mac_address'] as String?;
    if (mac == null) throw Exception("No default printer set. Please connect a printer first.");

    final device = BluetoothDevice.fromId(mac);
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();
      
      BluetoothCharacteristic? targetCharacteristic;
      
      for (final s in services) {
        // Many generic serial/printer UUIDs start with custom bases. Let's just find the first writeable one that's NOT a generic access service.
        if (s.uuid.str.startsWith('000018')) continue; // Skip standard services like Generic Access, Device Info
        for (final c in s.characteristics) {
          if (c.properties.writeWithoutResponse || c.properties.write) {
            targetCharacteristic = c;
            break;
          }
        }
        if (targetCharacteristic != null) break;
      }
      
      // Fallback
      if (targetCharacteristic == null) {
        for (final s in services) {
           for (final c in s.characteristics) {
            if (c.properties.writeWithoutResponse || c.properties.write) {
              targetCharacteristic = c;
              break;
            }
          }
        }
      }

      if (targetCharacteristic == null) {
        throw Exception("Could not find a writeable channel on this printer.");
      }
      
      // Chunking if necessary for some printers, but typically writing the whole array works with flutter_blue_plus MTU negotiations
      // Let's write in chunks of 512 bytes to be safe for older BLE printers
      final chunkSize = 512;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        await targetCharacteristic.write(bytes.sublist(i, end), withoutResponse: targetCharacteristic.properties.writeWithoutResponse);
        await Future.delayed(const Duration(milliseconds: 50));
      }

    } catch (e) {
      throw Exception("Printer connection failed: $e");
    } finally {
      await device.disconnect();
    }
  }
}
