import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/printer_repository.dart';

class PrinterSetupPage extends StatefulWidget {
  const PrinterSetupPage({super.key});

  @override
  State<PrinterSetupPage> createState() => _PrinterSetupPageState();
}

class _PrinterSetupPageState extends State<PrinterSetupPage> {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<PrinterRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Printer Setup')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repo.scanDevices(),
        builder: (context, snap) {
          final devices = snap.data ?? [];
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select a Bluetooth thermal printer (58mm/80mm)'),
              ),
              ...devices.map(
                (d) => ListTile(
                  title: Text(d['name'] as String? ?? 'Device'),
                  subtitle: Text(d['mac'] as String? ?? ''),
                  onTap: () async {
                    final uid =
                        context.read<AuthRepository>().currentSession?.userId;
                    if (uid == null) return;
                    await repo.saveDefaultPrinter(
                      userId: uid,
                      macAddress: d['mac'] as String,
                      name: d['name'] as String? ?? 'Printer',
                      paperWidthMm: 58,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Printer saved')),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
