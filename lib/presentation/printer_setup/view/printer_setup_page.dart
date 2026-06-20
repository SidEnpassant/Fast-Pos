import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/entities/receipt_payload.dart';

import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/printer_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterSetupPage extends StatefulWidget {
  const PrinterSetupPage({super.key});

  @override
  State<PrinterSetupPage> createState() => _PrinterSetupPageState();
}

class _PrinterSetupPageState extends State<PrinterSetupPage> {
  bool _isScanning = false;
  int _paperSize = 58;
  late final PrinterRepository _printerRepo;

  @override
  void initState() {
    super.initState();
    _printerRepo = context.read<PrinterRepository>();
    _loadCurrentConfig();
  }

  void _updatePdfSize(BuildContext context, String val) {
    if (val == '58mm') setState(() => _paperSize = 58);
    if (val == '80mm') setState(() => _paperSize = 80);

    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<ProfileRepository>().updateProfileFieldByLogicalKey(
        userId: uid,
        fieldKey: 'pdfBillSize',
        value: val,
      );
    }
  }

  Future<void> _loadCurrentConfig() async {
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      final printer = await context.read<PrinterRepository>().getDefaultPrinter(uid);
      if (printer != null && mounted) {
        setState(() {
          _paperSize = (printer['paper_width_mm'] as int?) ?? 58;
        });
      }
    }
  }

  Future<void> _requestPermissionsAndScan() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isGranted != true &&
        statuses[Permission.location]?.isGranted != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions required to scan for printers')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    final repo = context.read<PrinterRepository>();
    try {
      await repo.startScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _stopScan() async {
    await context.read<PrinterRepository>().stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _testPrint() async {
    try {
      await context.read<PrinterRepository>().printReceipt(
        const ReceiptPayload(
          businessName: "TEST PRINT",
          billNumber: "001",
          customerName: "John Doe",
          lines: [
            ReceiptLine(name: "Test Item 1", quantity: 1, total: 100),
            ReceiptLine(name: "Test Item 2", quantity: 2, total: 200),
          ],
          totalAmount: 300,
          paidAmount: 300,
          paymentMethod: "Cash",
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test print sent successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _printerRepo.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PrinterRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Test Print',
            onPressed: _testPrint,
          )
        ],
      ),
      body: Column(
        children: [
          BlocBuilder<DashboardHubBloc, DashboardHubState>(
            builder: (context, state) {
              final profile = state.profiles?.firstOrNull;
              final pdfSize = profile?.pdfBillSize ?? 'A4';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Default Bill Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('A4'),
                        selected: pdfSize == 'A4',
                        onSelected: (val) {
                          if (val) _updatePdfSize(context, 'A4');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('A5'),
                        selected: pdfSize == 'A5',
                        onSelected: (val) {
                          if (val) _updatePdfSize(context, 'A5');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('80mm'),
                        selected: pdfSize == '80mm',
                        onSelected: (val) {
                          if (val) _updatePdfSize(context, '80mm');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('58mm'),
                        selected: pdfSize == '58mm',
                        onSelected: (val) {
                          if (val) _updatePdfSize(context, '58mm');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          if (_isScanning) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discovered Devices', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_isScanning)
                  TextButton.icon(
                    onPressed: _stopScan,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  )
                else
                  TextButton.icon(
                    onPressed: _requestPermissionsAndScan,
                    icon: const Icon(Icons.search),
                    label: const Text('Scan'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: repo.scanDevices(),
              builder: (context, snap) {
                final devices = snap.data ?? [];
                if (devices.isEmpty && !_isScanning) {
                  return const Center(child: Text('No devices found. Tap Scan.'));
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final d = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(d['name'] as String? ?? 'Device'),
                      subtitle: Text(d['mac'] as String? ?? ''),
                      onTap: () async {
                        final uid = context.read<AuthRepository>().currentSession?.userId;
                        if (uid == null) return;
                        await repo.saveDefaultPrinter(
                          userId: uid,
                          macAddress: d['mac'] as String,
                          name: d['name'] as String? ?? 'Printer',
                          paperWidthMm: _paperSize,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Printer saved as default')),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
