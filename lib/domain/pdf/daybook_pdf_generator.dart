import 'dart:io';
import 'package:intl/intl.dart';
import 'package:inventopos/application/daybook/compute_day_book_use_case.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inventopos/domain/entities/cash_entry.dart';
import 'package:inventopos/presentation/daybook/bloc/daybook_bloc.dart'; // To access DayBookSummary

class DayBookPdfGenerator {
  static Future<File> generate(DayBookSummary summary) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Day Book Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Fast POS', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total In', summary.totalIn, PdfColors.green700, currencyFormat),
                    _buildSummaryItem('Total Out', summary.totalOut, PdfColors.red700, currencyFormat),
                    _buildSummaryItem('Net Balance', summary.netBalance, PdfColors.blue700, currencyFormat),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Entries Table
              pw.Text('Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(3.0),
                  3: const pw.FlexColumnWidth(2.0),
                },
                data: <List<String>>[
                  ['Date', 'Type', 'Note / Ref', 'Amount'],
                  ...summary.entries.map((entry) {
                    final isIn = entry.type == 'in';
                    final amountText = '${isIn ? '+' : '-'}${currencyFormat.format(entry.amount)}';
                    return [
                      dateFormat.format(entry.entryDate),
                      isIn ? 'Cash In' : 'Cash Out',
                      '${entry.note ?? ''} ${entry.referenceType != null ? '(${entry.referenceType})' : ''}',
                      amountText,
                    ];
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/DayBook_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryItem(String label, double amount, PdfColor color, NumberFormat format) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(
          format.format(amount),
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
