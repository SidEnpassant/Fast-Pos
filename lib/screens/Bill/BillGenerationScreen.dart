// bill_generation_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class BillGenerationScreen extends StatefulWidget {
  const BillGenerationScreen({Key? key}) : super(key: key);

  @override
  State<BillGenerationScreen> createState() => _BillGenerationScreenState();
}

class _BillGenerationScreenState extends State<BillGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  String _paymentMethod = 'cash';
  String _paymentStatus = 'complete';
  double _paidAmount = 0.0;
  final List<ProductItem> _products = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _products.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Bill'),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the first screen
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Customer Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter customer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter phone number';
                              }
                              if (value!.length != 10) {
                                return 'Please enter valid phone number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Products Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Products',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showAddProductDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Product'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_products.isEmpty)
                            const Center(
                              child: Text(
                                'No products added yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                return ListTile(
                                  title: Text(product.name),
                                  subtitle: Text(
                                    '₹${product.price.toStringAsFixed(2)} x ${product.quantity}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${(product.price * product.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        onPressed: () {
                                          setState(() {
                                            _products.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          if (_products.isNotEmpty) ...[
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Total: ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _paymentMethod,
                            decoration: const InputDecoration(
                              labelText: 'Payment Method',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'cash',
                                child: Text('Cash'),
                              ),
                              DropdownMenuItem(
                                value: 'upi',
                                child: Text('UPI'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _paymentStatus,
                            decoration: const InputDecoration(
                              labelText: 'Payment Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'complete',
                                child: Text('Fully Paid'),
                              ),
                              DropdownMenuItem(
                                value: 'partial',
                                child: Text('Partially Paid'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _paymentStatus = value!;
                                if (value == 'complete') {
                                  _paidAmount = totalAmount;
                                }
                              });
                            },
                          ),
                          if (_paymentStatus == 'partial') ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _paidAmount.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Paid Amount',
                                border: OutlineInputBorder(),
                                prefixText: '₹',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter paid amount';
                                }
                                final amount = double.tryParse(value!);
                                if (amount == null) {
                                  return 'Please enter valid amount';
                                }
                                if (amount <= 0) {
                                  return 'Amount must be greater than 0';
                                }
                                if (amount > totalAmount) {
                                  return 'Amount cannot be greater than total';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _paidAmount = double.tryParse(value) ?? 0;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generate Bill Button
                  ElevatedButton.icon(
                    onPressed: _products.isEmpty ? null : _generateBill,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Generate Bill'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showAddProductDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final price = double.tryParse(priceController.text) ?? 0;
              final quantity = int.tryParse(quantityController.text) ?? 0;

              if (name.isNotEmpty && price > 0 && quantity > 0) {
                setState(() {
                  _products.add(ProductItem(
                    name: name,
                    price: price,
                    quantity: quantity,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get business name from user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final businessName = userDoc.data()?['businessName'] as String?;
      if (businessName == null) throw Exception('Business name not found');

      final totalAmount = _products.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      // Create bill document
      final billRef = await FirebaseFirestore.instance.collection('bills').add({
        'userId': user.uid,
        'businessName': businessName,
        'customerName': _customerNameController.text,
        'customerPhone': _customerPhoneController.text,
        'products': _products.map((p) => p.toMap()).toList(),
        'totalAmount': totalAmount,
        'paidAmount': _paymentStatus == 'complete' ? totalAmount : _paidAmount,
        'paymentMethod': _paymentMethod,
        'paymentStatus': _paymentStatus,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add transaction to the transactions collection
      await _addTransaction(
          user.uid,
          totalAmount,
          _paymentStatus == 'complete' ? totalAmount : _paidAmount,
          _paymentStatus);

      // Generate PDF and share
      final pdfPath = await _generateAndSharePDF(billRef.id);

      // Show success dialog with options
      _showPDFOptionsDialog(pdfPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addTransaction(String userId, double totalAmount,
      double paidAmount, String paymentStatus) async {
    CollectionReference transactions =
        FirebaseFirestore.instance.collection('transactions');

    // Determine the amount and isComplete status
    double amount = paymentStatus == 'complete' ? totalAmount : paidAmount;
    bool isComplete = paymentStatus == 'complete';

    Map<String, dynamic> transactionData = {
      'businessId': userId, // Using userId as businessId
      'amount': amount, // Add totalAmount or paidAmount based on paymentStatus
      'isComplete': isComplete, // True if payment is complete, false otherwise
      'date': FieldValue.serverTimestamp(), // Add current timestamp as date
    };

    try {
      await transactions.add(transactionData);
      print('Transaction added successfully');
    } catch (e) {
      print('Failed to add transaction: $e');
    }
  }

  Future<String> _generateAndSharePDF(String billId) async {
    // Create a PDF document
    final pdf = pw.Document();

    // Fetch additional business details from Firestore
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final businessName = userDoc.data()?['businessName'] as String? ?? '';
    final gstNumber = userDoc.data()?['gstNumber'] as String? ?? '';
    final businessAddress = userDoc.data()?['businessAddress'] as String? ??
        ''; // Fetch Business Address
    final businessPhone = userDoc.data()?['phoneNumber'] as String? ?? '';
    final signatureUrl = userDoc.data()?['signatureUrl'] as String? ?? '';

    // Load signature image before creating the page
    Uint8List? signatureImage;
    if (signatureUrl.isNotEmpty) {
      try {
        signatureImage = await _getSignatureImage(signatureUrl);
      } catch (e) {
        print('Error loading signature: $e');
      }
    }

    // Calculate total amount
    final totalAmount = _products.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
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

              // GST Section (if available)
              if (gstNumber.isNotEmpty) ...[
                pw.Center(
                  child: pw.Text(
                    'GST No: $gstNumber',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 4),
              ],

              // Business Address Section (if available)
              if (businessAddress.isNotEmpty) ...[
                pw.Center(
                  child: pw.Text(
                    'Address: $businessAddress',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 8),
              ],

              // Divider
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),

              // Bill Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill No: $billId',
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text(
                          'Date: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Customer Details:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${_customerNameController.text}',
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Ph: ${_customerPhoneController.text}',
                          style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Products Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4), // Product name
                  1: const pw.FlexColumnWidth(2), // Price
                  2: const pw.FlexColumnWidth(1), // Qty
                  3: const pw.FlexColumnWidth(2), // Total
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Product',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Price',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qty',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Product Rows
                  ..._products.map(
                    (product) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child:
                              pw.Text('₹${product.price.toStringAsFixed(2)}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${product.quantity}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '₹${(product.price * product.quantity).toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Total Section
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Total Amount: ',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('₹${totalAmount.toStringAsFixed(2)}',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    if (_paymentStatus == 'partial') ...[
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Paid Amount: '),
                          pw.Text('₹${_paidAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Balance: '),
                          pw.Text(
                              '₹${(totalAmount - _paidAmount).toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Text('Payment Method: ${_paymentMethod.toUpperCase()}'),
                    pw.Text(
                        'Payment Status: ${_paymentStatus == 'complete' ? 'Fully Paid' : 'Partially Paid'}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Footer Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Contact Details:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Phone: $businessPhone',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  if (signatureImage != null)
                    pw.Column(
                      children: [
                        pw.Container(
                          height: 50,
                          width: 100,
                          child: pw.Image(
                            pw.MemoryImage(signatureImage),
                          ),
                        ),
                        pw.Text('Authorized Signature',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Get the directory to save the PDF
    final directory = await getApplicationDocumentsDirectory();
    final pdfPath = '${directory.path}/bill_$billId.pdf';

    // Save the PDF document
    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());

    return pdfPath;
  }

// Helper function to get signature image from URL
  Future<Uint8List> _getSignatureImage(String signatureUrl) async {
    try {
      final response = await http.get(Uri.parse(signatureUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('Failed to load signature image');
    } catch (e) {
      print('Error loading signature: $e');
      throw e;
    }
  }

  Future<void> _showPDFOptionsDialog(String pdfPath) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bill Generated Successfully'),
          content: const Text('What would you like to do with the PDF?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Implement download functionality
                _downloadPDF(pdfPath);
                Navigator.of(context).pop();
              },
              child: const Text('Download PDF'),
            ),
            TextButton(
              onPressed: () {
                // Implement view functionality
                _viewPDF(pdfPath);
                Navigator.of(context).pop();
              },
              child: const Text('View PDF'),
            ),
            TextButton(
              onPressed: () {
                // Implement share functionality
                _sharePDF(pdfPath);
                Navigator.of(context).pop();
              },
              child: const Text('Share via WhatsApp'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadPDF(String pdfPath) async {
    // In a Flutter mobile app, saving files is generally done in the app's local directory.
    // If you want to download a file, you'll typically save it to the device's storage.
    try {
      // Get the directory to save the PDF
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/downloaded_bill.pdf';

      // Copy the PDF file to the local path
      final file = File(pdfPath);
      await file.copy(localPath);

      // Show a success message
      print('PDF downloaded successfully to $localPath');
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }

  // Future<void> _viewPDF(String pdfPath) async {

  //   // Implement your PDF viewing logic here
  // }
  Future<void> _viewPDF(String pdfPath) async {
    try {
      // Open the PDF using the Open File package
      final result = await OpenFile.open(pdfPath);
      if (result.type == ResultType.error) {
        print('Error opening PDF: ${result.message}');
      }
    } catch (e) {
      print('Error viewing PDF: $e');
    }
  }

  Future<void> _sharePDF(String pdfPath) async {
    try {
      XFile xFile = XFile(pdfPath);
      // Share the XFile
      await Share.shareXFiles([xFile], text: 'Here is your bill.');
      // // Share the PDF using the Share Plus package
      // await Share.shareFiles([pdfPath], text: 'Here is your bill.');
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }
}

class ProductItem {
  final String name;
  final double price;
  final int quantity;

  ProductItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}
