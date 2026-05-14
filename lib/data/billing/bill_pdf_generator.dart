import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds invoice PDF bytes and writes them under app documents (infrastructure).
class BillPdfGenerator {
  BillPdfGenerator({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<String> writeToApplicationDocuments({
    required String billId,
    required String sequentialBillNumber,
    required UserProfile merchant,
    required String customerName,
    required String customerPhone,
    required List<BillDraftLine> lines,
    required String paymentMethod,
    required String paymentStatus,
    required double paidAmount,
    required double totalAmount,
  }) async {
    final businessName = merchant.businessName ?? '';
    final gstNumber = merchant.gstNumber ?? '';
    final businessAddress = merchant.businessAddress ?? '';
    final businessPhone = merchant.phoneNumber ?? '';
    final signatureUrl = merchant.signatureUrl ?? '';
    final billRules = merchant.billRules ?? '';

    Uint8List? signatureImage;
    if (signatureUrl.isNotEmpty) {
      try {
        signatureImage = await _loadUrlBytes(signatureUrl);
      } catch (_) {}
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  businessName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              if (gstNumber.isNotEmpty) ...[
                pw.Center(
                  child: pw.Text(
                    'GST No: $gstNumber',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 4),
              ],
              if (businessAddress.isNotEmpty) ...[
                pw.Center(
                  child: pw.Text(
                    'Address: $businessAddress',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill No: $sequentialBillNumber \n$billId',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Customer Details:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(customerName,
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text(
                        'Ph: $customerPhone',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Product',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Price',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...lines.expand((product) {
                    return [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(product.name),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Rs. ${product.price.toStringAsFixed(2)}',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${product.quantity}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Rs. ${(product.price * product.quantity).toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                      if (product.comment != null &&
                          product.comment!.isNotEmpty)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Comment: ${product.comment}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            ),
                            pw.SizedBox(),
                            pw.SizedBox(),
                            pw.SizedBox(),
                          ],
                        ),
                    ];
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total Amount: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Rs. ${totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    if (paymentStatus == 'partial') ...[
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Paid Amount: '),
                          pw.Text('Rs. ${paidAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Balance: '),
                          pw.Text(
                            'Rs. ${(totalAmount - paidAmount).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Text('Payment Method: ${paymentMethod.toUpperCase()}'),
                    pw.Text(
                      'Payment Status: ${paymentStatus == 'complete' ? 'Fully Paid' : 'Partially Paid'}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Contact Details:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Phone: $businessPhone',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (billRules.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Terms & Conditions:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          billRules,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ],
                  ),
                  if (signatureImage != null)
                    pw.Column(
                      children: [
                        pw.Container(
                          height: 50,
                          width: 100,
                          child: pw.Image(pw.MemoryImage(signatureImage)),
                        ),
                        pw.Text(
                          'Authorized Signature',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final pdfPath = '${directory.path}/bill_$billId.pdf';
    await File(pdfPath).writeAsBytes(await pdf.save());
    return pdfPath;
  }

  Future<Uint8List> _loadUrlBytes(String signatureUrl) async {
    final response = await _http.get(Uri.parse(signatureUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw StateError('Failed to load signature image');
  }
}
