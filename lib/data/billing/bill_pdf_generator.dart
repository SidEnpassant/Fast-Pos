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
    List<Map<String, dynamic>>? discountBreakdown,
    DateTime? updatedAt,
  }) async {
    final businessName = merchant.businessName ?? '';
    final gstNumber = merchant.gstNumber ?? '';
    final businessAddress = merchant.businessAddress ?? '';
    final businessPhone = merchant.phoneNumber ?? '';
    final signatureUrl = merchant.signatureUrl ?? '';
    final billRules = merchant.billRules ?? '';
    final pdfSize = merchant.pdfBillSize; // 'A4', 'A5', '80mm', '58mm'

    final bool hasTax = lines.any((e) => e.taxAmount > 0);
    final String invoiceHeader = merchant.isCompositionDealer
        ? 'BILL OF SUPPLY'
        : (hasTax ? 'TAX INVOICE' : 'INVOICE');

    Uint8List? signatureImage;
    if (signatureUrl.isNotEmpty) {
      try {
        signatureImage = await _loadUrlBytes(signatureUrl);
      } catch (_) {}
    }

    final pdf = pw.Document();

    PdfPageFormat format;
    bool isThermal = false;
    double thermalMargin = 10;
    
    switch (pdfSize) {
      case 'A5':
        format = PdfPageFormat.a5;
        break;
      case '80mm':
        format = PdfPageFormat.roll80;
        isThermal = true;
        thermalMargin = 8;
        break;
      case '58mm':
        format = PdfPageFormat.roll57;
        isThermal = true;
        thermalMargin = 4;
        break;
      case 'A4':
      default:
        format = PdfPageFormat.a4;
        break;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: isThermal ? pw.EdgeInsets.all(thermalMargin) : const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          if (isThermal) {
            return _buildThermalLayout(
              businessName: businessName,
              invoiceHeader: invoiceHeader,
              gstNumber: gstNumber,
              businessAddress: businessAddress,
              sequentialBillNumber: sequentialBillNumber,
              billId: billId,
              customerName: customerName,
              customerPhone: customerPhone,
              lines: lines,
              hasTax: hasTax,
              discountBreakdown: discountBreakdown,
              totalAmount: totalAmount,
              paidAmount: paidAmount,
              paymentMethod: paymentMethod,
              paymentStatus: paymentStatus,
              updatedAt: updatedAt,
              businessPhone: businessPhone,
              billRules: billRules,
              is58mm: pdfSize == '58mm',
            );
          } else {
            return _buildStandardLayout(
              businessName: businessName,
              invoiceHeader: invoiceHeader,
              gstNumber: gstNumber,
              businessAddress: businessAddress,
              sequentialBillNumber: sequentialBillNumber,
              billId: billId,
              customerName: customerName,
              customerPhone: customerPhone,
              lines: lines,
              hasTax: hasTax,
              discountBreakdown: discountBreakdown,
              totalAmount: totalAmount,
              paidAmount: paidAmount,
              paymentMethod: paymentMethod,
              paymentStatus: paymentStatus,
              updatedAt: updatedAt,
              businessPhone: businessPhone,
              billRules: billRules,
              signatureImage: signatureImage,
            );
          }
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final pdfPath = '${directory.path}/bill_$billId.pdf';
    await File(pdfPath).writeAsBytes(await pdf.save());
    return pdfPath;
  }

  pw.Widget _buildStandardLayout({
    required String businessName,
    required String invoiceHeader,
    required String gstNumber,
    required String businessAddress,
    required String sequentialBillNumber,
    required String billId,
    required String customerName,
    required String customerPhone,
    required List<BillDraftLine> lines,
    required bool hasTax,
    required List<Map<String, dynamic>>? discountBreakdown,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethod,
    required String paymentStatus,
    required DateTime? updatedAt,
    required String businessPhone,
    required String billRules,
    required Uint8List? signatureImage,
  }) {
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
        pw.Center(
          child: pw.Text(
            invoiceHeader,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        if (gstNumber.isNotEmpty) ...[
          pw.Center(
            child: pw.Text(
              'GSTIN: $gstNumber',
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
                pw.Text(customerName, style: const pw.TextStyle(fontSize: 12)),
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
          columnWidths: hasTax
              ? {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.5),
                }
              : {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2),
                },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: hasTax
                  ? [
                      _th('Product'),
                      _th('HSN'),
                      _th('Price'),
                      _th('Qty'),
                      _th('Total+Tax'),
                    ]
                  : [
                      _th('Product'),
                      _th('Price'),
                      _th('Qty'),
                      _th('Total'),
                    ],
            ),
            ...lines.expand((product) {
              final qtyStr = product.quantity % 1 == 0
                  ? product.quantity.toInt().toString()
                  : product.quantity.toStringAsFixed(2);
              final lineTotal = (product.price * product.quantity) + product.taxAmount;

              return [
                pw.TableRow(
                  children: hasTax
                      ? [
                          _td(product.name),
                          _td(product.hsnCode ?? ''),
                          _td('Rs. ${product.price.toStringAsFixed(2)}'),
                          _td('$qtyStr ${product.uom}'),
                          _td('Rs. ${lineTotal.toStringAsFixed(2)}\n(${product.gstPercent ?? 0}%)', fontSize: 10),
                        ]
                      : [
                          _td(product.name),
                          _td('Rs. ${product.price.toStringAsFixed(2)}'),
                          _td('$qtyStr ${product.uom}'),
                          _td('Rs. ${(product.price * product.quantity).toStringAsFixed(2)}'),
                        ],
                ),
                if (product.comment != null && product.comment!.isNotEmpty)
                  pw.TableRow(
                    children: hasTax
                        ? [_tdComment('Comment: ${product.comment}'), pw.SizedBox(), pw.SizedBox(), pw.SizedBox(), pw.SizedBox()]
                        : [_tdComment('Comment: ${product.comment}'), pw.SizedBox(), pw.SizedBox(), pw.SizedBox()],
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
              if (hasTax) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Tax Amount: '),
                    pw.Text('Rs. ${lines.fold<double>(0, (p, c) => p + c.taxAmount).toStringAsFixed(2)}'),
                  ],
                ),
                pw.SizedBox(height: 4),
              ],
              if (discountBreakdown != null)
                ...discountBreakdown.map((discount) {
                  if (discount['type'] == 'loyalty') {
                    return pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text('Loyalty Used (${discount['points_redeemed']} pts): '),
                            pw.Text('- Rs. ${(discount['amount'] as num).toStringAsFixed(2)}'),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                      ],
                    );
                  }
                  return pw.SizedBox();
                }),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Amount: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                    pw.Text('Rs. ${(totalAmount - paidAmount).toStringAsFixed(2)}'),
                  ],
                ),
              ],
              pw.SizedBox(height: 8),
              pw.Text('Payment Method: ${paymentMethod.toUpperCase()}'),
              pw.Text('Payment Status: ${paymentStatus == 'complete' ? 'Fully Paid' : 'Partially Paid'}'),
              if (updatedAt != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(updatedAt)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
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
                pw.Text('Contact Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Phone: $businessPhone', style: const pw.TextStyle(fontSize: 10)),
                if (billRules.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(billRules, style: const pw.TextStyle(fontSize: 8)),
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
                  pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildThermalLayout({
    required String businessName,
    required String invoiceHeader,
    required String gstNumber,
    required String businessAddress,
    required String sequentialBillNumber,
    required String billId,
    required String customerName,
    required String customerPhone,
    required List<BillDraftLine> lines,
    required bool hasTax,
    required List<Map<String, dynamic>>? discountBreakdown,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethod,
    required String paymentStatus,
    required DateTime? updatedAt,
    required String businessPhone,
    required String billRules,
    required bool is58mm,
  }) {
    final double fontSize = is58mm ? 8 : 10;
    final double headerSize = is58mm ? 12 : 16;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            businessName.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            invoiceHeader,
            style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),
        if (gstNumber.isNotEmpty)
          pw.Center(child: pw.Text('GSTIN: $gstNumber', style: pw.TextStyle(fontSize: fontSize))),
        if (businessAddress.isNotEmpty)
          pw.Center(child: pw.Text(businessAddress, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: fontSize))),
        if (businessPhone.isNotEmpty)
          pw.Center(child: pw.Text('Ph: $businessPhone', style: pw.TextStyle(fontSize: fontSize))),
        
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 4),
        
        pw.Text('Bill No: $sequentialBillNumber', style: pw.TextStyle(fontSize: fontSize)),
        pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: fontSize)),
        pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: fontSize)),
        if (customerPhone.isNotEmpty)
          pw.Text('Cust Ph: $customerPhone', style: pw.TextStyle(fontSize: fontSize)),
        
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 4),
        
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(flex: 5, child: pw.Text('Item', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 3, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 2),
        
        ...lines.map((product) {
          final qtyStr = product.quantity % 1 == 0
              ? product.quantity.toInt().toString()
              : product.quantity.toStringAsFixed(2);
          final lineTotal = (product.price * product.quantity) + product.taxAmount;
          
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 5, child: pw.Text(product.name, style: pw.TextStyle(fontSize: fontSize))),
                  pw.Expanded(flex: 2, child: pw.Text(qtyStr, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: fontSize))),
                  pw.Expanded(flex: 3, child: pw.Text(lineTotal.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: fontSize))),
                ],
              ),
              if (hasTax && product.taxAmount > 0)
                pw.Text('  + Tax: ${product.taxAmount.toStringAsFixed(2)} (${product.gstPercent ?? 0}%)', style: pw.TextStyle(fontSize: fontSize - 2, color: PdfColors.grey700)),
              if (product.comment != null && product.comment!.isNotEmpty)
                pw.Text('  * ${product.comment}', style: pw.TextStyle(fontSize: fontSize - 2, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 2),
            ]
          );
        }),
        
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 4),
        
        if (hasTax)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tax Amount:', style: pw.TextStyle(fontSize: fontSize)),
              pw.Text(lines.fold<double>(0, (p, c) => p + c.taxAmount).toStringAsFixed(2), style: pw.TextStyle(fontSize: fontSize)),
            ],
          ),
          
        if (discountBreakdown != null)
          ...discountBreakdown.map((discount) {
            if (discount['type'] == 'loyalty') {
              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Loyalty (-${discount['points_redeemed']} pts):', style: pw.TextStyle(fontSize: fontSize)),
                  pw.Text('-${(discount['amount'] as num).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: fontSize)),
                ],
              );
            }
            return pw.SizedBox();
          }),
          
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL:', style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold)),
            pw.Text('Rs. ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 4),
        
        if (paymentStatus == 'partial') ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Paid:', style: pw.TextStyle(fontSize: fontSize)),
              pw.Text(paidAmount.toStringAsFixed(2), style: pw.TextStyle(fontSize: fontSize)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Balance:', style: pw.TextStyle(fontSize: fontSize)),
              pw.Text((totalAmount - paidAmount).toStringAsFixed(2), style: pw.TextStyle(fontSize: fontSize)),
            ],
          ),
        ],
        
        pw.SizedBox(height: 8),
        pw.Center(child: pw.Text('Paid via $paymentMethod', style: pw.TextStyle(fontSize: fontSize))),
        pw.SizedBox(height: 12),
        pw.Center(child: pw.Text('Thank you for shopping!', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
        
        if (billRules.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
          pw.Text('T&C:', style: pw.TextStyle(fontSize: fontSize - 2, fontWeight: pw.FontWeight.bold)),
          pw.Text(billRules, style: pw.TextStyle(fontSize: fontSize - 2)),
        ],
      ],
    );
  }

  pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget _td(String text, {double? fontSize}) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text, style: fontSize != null ? pw.TextStyle(fontSize: fontSize) : null),
      );

  pw.Widget _tdComment(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
        ),
      );

  Future<Uint8List> _loadUrlBytes(String signatureUrl) async {
    final response = await _http.get(Uri.parse(signatureUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw StateError('Failed to load signature image');
  }
}
