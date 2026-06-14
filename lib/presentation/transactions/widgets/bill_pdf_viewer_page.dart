import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/billing/download_bill_pdf_use_case.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:open_file/open_file.dart';

/// Opens invoice PDF from Supabase storage, local cache, or cloud URL.
Future<void> openBillPdf(BuildContext context, String? pdfUrl) async {
  if (pdfUrl == null || pdfUrl.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice PDF not available for this bill'),
        ),
      );
    }
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) =>  Center(
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

  try {
    final path = await context.read<DownloadBillPdfUseCase>()(
      billId: '',
      pdfUrl: pdfUrl,
    );
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (path != null) {
      await OpenFile.open(path);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download PDF')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// Resolves the latest PDF for [bill] and opens it.
Future<void> openBillPdfForBill(BuildContext context, Bill bill) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) =>  Center(
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

  try {
    var pdfUrl = bill.pdfUrl;
    if (pdfUrl == null || pdfUrl.isEmpty) {
      final fresh =
          await context.read<BillsRepository>().fetchBillById(bill.id);
      pdfUrl = fresh?.pdfUrl;
    }

    final path = await context.read<DownloadBillPdfUseCase>()(
      billId: bill.id,
      pdfUrl: pdfUrl,
    );

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (path != null) {
      await OpenFile.open(path);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice PDF not available for this bill'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class BillPdfViewerPage extends StatelessWidget {
  const BillPdfViewerPage({super.key, required this.pdfUrl});

  final String pdfUrl;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openBillPdf(context, pdfUrl);
      Navigator.pop(context);
    });
    return  Scaffold(
      body: Center(
        child: AppShimmer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
