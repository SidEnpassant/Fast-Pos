import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';

class BillGenerationScreen extends StatefulWidget {
  const BillGenerationScreen({Key? key}) : super(key: key);

  @override
  State<BillGenerationScreen> createState() => _BillGenerationScreenState();
}

class _BillGenerationScreenState extends State<BillGenerationScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  String _paymentMethod = 'cash';
  String _paymentStatus = 'complete';
  double _paidAmount = 0.0;
  final List<ProductItem> _products = [];
  stt.SpeechToText _speech = stt.SpeechToText();

  bool _isLoading = false;
  bool _isListening = false;
  String _voiceInputText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _textRecognizer.close();
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
        title: Text(
          'Generate Bill',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Generating Bill...',
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer Details Card
                  _buildCard(
                    'Customer Details',
                    Icons.person_outline,
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextFormField(
                              controller: _customerNameController,
                              decoration: _buildInputDecoration(
                                'Customer Name',
                                Icons.person,
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter customer name';
                                }
                                return null;
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.red : Colors.grey,
                              ),
                              onPressed: _listen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customerPhoneController,
                          decoration: _buildInputDecoration(
                            'Phone Number',
                            Icons.phone,
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
                  ).animate().fadeIn().slideX(),

                  const SizedBox(height: 16),

                  // Products Card
                  _buildCard(
                    'Products',
                    Icons.shopping_cart_outlined,
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAddProductDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Product'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_products.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_basket_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No products added yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return Slidable(
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        setState(() {
                                          _products.removeAt(index);
                                        });
                                      },
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                    ),
                                  ],
                                ),
                                child: Card(
                                  elevation: 0,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[50],
                                      child: Text(
                                        product.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      product.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '₹${product.price.toStringAsFixed(2)} × ${product.quantity}',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    trailing: Text(
                                      '₹${(product.price * product.quantity).toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn().slideX();
                            },
                          ),
                        if (_products.isNotEmpty) ...[
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Total: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .slideX(delay: const Duration(milliseconds: 200)),

                  const SizedBox(height: 16),

                  // Payment Details Card
                  _buildCard(
                    'Payment Details',
                    Icons.payment_outlined,
                    Column(
                      children: [
                        _buildDropdownField(
                          'Payment Method',
                          _paymentMethod,
                          {
                            'cash': 'Cash Payment',
                            'upi': 'UPI Payment',
                          },
                          (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          'Payment Status',
                          _paymentStatus,
                          {
                            'complete': 'Fully Paid',
                            'partial': 'Partially Paid',
                          },
                          (value) {
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
                            decoration: _buildInputDecoration(
                              'Paid Amount',
                              Icons.money,
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
                  )
                      .animate()
                      .fadeIn()
                      .slideX(delay: const Duration(milliseconds: 400)),

                  const SizedBox(height: 24),

                  // Generate Bill Button
                  ElevatedButton.icon(
                    onPressed: _products.isEmpty ? null : _generateBill,
                    icon: const Icon(Icons.receipt_long),
                    label: Text(
                      'Generate Bill',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .slideY(delay: const Duration(milliseconds: 600)),
                ],
              ),
            ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _voiceInputText = val.recognizedWords;
            _customerNameController.text = _voiceInputText;
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Widget _buildCard(String title, IconData icon, Widget content) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    Map<String, String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _buildInputDecoration(
        label,
        items.keys.first == 'cash' ? Icons.payments : Icons.check_circle,
      ),
      items: items.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue[700]!),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Future<void> _showAddProductDialog([String? initialProductName]) async {
    final nameController = TextEditingController(text: initialProductName);
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final commentController = TextEditingController();
    final stt = SpeechToText();
    bool isListening = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name*',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () async {
                            Navigator.pop(context);
                            final scannedName = await _showBarcodeScanner();
                            if (scannedName != null) {
                              _showAddProductDialog(scannedName);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: () async {
                            Navigator.pop(context);
                            final recognizedText = await _showTextRecognition();
                            if (recognizedText != null) {
                              _showAddProductDialog(recognizedText);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price*',
                    border: OutlineInputBorder(),
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity*',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Comments (Optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: isListening ? Colors.red : null,
                      ),
                      onPressed: () async {
                        if (!isListening) {
                          bool available = await stt.initialize();
                          if (available) {
                            setDialogState(() => isListening = true);
                            stt.listen(
                              onResult: (result) {
                                setDialogState(() {
                                  commentController.text =
                                      result.recognizedWords;
                                });
                              },
                              listenFor: const Duration(seconds: 30),
                              pauseFor: const Duration(seconds: 5),
                              partialResults: true,
                              cancelOnError: true,
                              listenMode: ListenMode.confirmation,
                            );
                          }
                        } else {
                          setDialogState(() => isListening = false);
                          stt.stop();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0;
                final quantity = int.tryParse(quantityController.text) ?? 0;
                final comment = commentController.text.trim();

                if (name.isNotEmpty && price > 0 && quantity > 0) {
                  // Use the parent's setState to update the list
                  Navigator.pop(context);
                  setState(() {
                    _products.add(ProductItem(
                      name: name,
                      price: price,
                      quantity: quantity,
                      comment: comment.isNotEmpty
                          ? comment
                          : null, // Make comment optional
                    ));
                  });
                } else {
                  // Show error message for required fields
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please fill in all required fields correctly'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showBarcodeScanner() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      return null;
    }
    String? productName;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text('Scan Barcode'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              // leadingWidth: IconButton(onPressed: (){}, icon: Icons.lightbulb),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    // onDetect: (capture) async {
                    //   final List<Barcode> barcodes = capture.barcodes;
                    //   if (barcodes.isNotEmpty) {
                    //     final barcode = barcodes.first.rawValue;

                    //     // Look up product name from barcode
                    //     try {
                    //       final response = await http.get(Uri.parse(
                    //           'https://api.upcitemdb.com/prod/trial/lookup$barcode.json'));

                    //       if (response.statusCode == 200) {
                    //         final data = json.decode(response.body);
                    //         if (data['status'] == 1) {
                    //           productName = data['product']['product_name'];
                    //           Navigator.pop(context); // Close scanner
                    //         }
                    //       }
                    //     } catch (e) {
                    //       print('Error looking up product: $e');
                    //     }
                    //   }
                    // },

                    onDetect: (capture) async {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final barcode = barcodes.first.rawValue;

                        // Look up product name from barcode
                        try {
                          final url =
                              'https://api.barcodelookup.com/v3/products';
                          final apiKey =
                              'ao4ts806g5qm9gp0w80825kpadku3j'; // Replace with your Barcode Lookup API key
                          final queryParameters = {
                            'barcode':
                                barcode, // Sending the barcode value to lookup
                            'key': apiKey,
                          };

                          // Make the GET request to Barcode Lookup API
                          final response = await http.get(Uri.parse(
                              '$url?${Uri(queryParameters: queryParameters)}'));

                          if (response.statusCode == 200) {
                            final data = json.decode(response.body);

                            // Check if products are found
                            if (data['products'] != null &&
                                data['products'].isNotEmpty) {
                              final product = data['products']
                                  [0]; // Get the first product from response
                              final productName = product['product_name'];

                              // Close scanner and update the product name
                              Navigator.pop(context, productName);
                            } else {
                              print('Product not found or error in response.');
                            }
                          } else {
                            print(
                                'Failed to lookup product. Status Code: ${response.statusCode}');
                          }
                        } catch (e) {
                          print('Error looking up product: $e');
                        }
                      }
                    },
                  ),
                  // Overlay for scan area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 300),
                            child: Text(
                              'Place barcode inside the box',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return productName;
  }

  Future<String?> _showTextRecognition() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      return null;
    }

    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    // Create a set to store selected text items
    final Set<String> selectedTexts = {};

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder to manage local state
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Text (Multiple)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected texts preview
                      if (selectedTexts.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Items:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: selectedTexts
                                    .map((text) => Chip(
                                          label: Text(text),
                                          deleteIcon:
                                              const Icon(Icons.close, size: 18),
                                          onDeleted: () {
                                            setState(() {
                                              selectedTexts.remove(text);
                                            });
                                          },
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Recognized text items
                      ...recognizedText.blocks
                          .expand((block) => block.lines)
                          .map((line) => InkWell(
                                onTap: () {
                                  setState(() {
                                    if (selectedTexts.contains(line.text)) {
                                      selectedTexts.remove(line.text);
                                    } else {
                                      selectedTexts.add(line.text);
                                    }
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedTexts.contains(line.text)
                                        ? Colors.blue.withOpacity(0.1)
                                        : null,
                                    border: Border.all(
                                      color: selectedTexts.contains(line.text)
                                          ? Colors.blue
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    line.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: selectedTexts.contains(line.text)
                                          ? Colors.blue
                                          : null,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedTexts.isEmpty
                  ? null
                  : () {
                      // Combine selected texts with spaces
                      final combinedText = selectedTexts.join(' ');
                      Navigator.pop(context, combinedText);
                    },
              child: const Text('Done'),
            ),
          ],
        ),
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

  Future<String> _getNextBillNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);

    // Run this in a transaction to ensure atomic updates
    return FirebaseFirestore.instance
        .runTransaction<String>((transaction) async {
      // Get the current document
      final userDoc = await transaction.get(userRef);

      // Get the current bill number, default to 0 if it doesn't exist
      final currentBillNumber = userDoc.data()?['lastBillNumber'] as int? ?? 0;

      // Increment the bill number
      final nextBillNumber = currentBillNumber + 1;

      // Update the document with the new bill number
      transaction.update(userRef, {'lastBillNumber': nextBillNumber});

      // Return the new bill number as a string
      return nextBillNumber.toString();
    });
  }

  Future<String> _generateAndSharePDF(String billId) async {
    // Get the next sequential bill number
    final sequentialBillNumber = await _getNextBillNumber();
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
    final billRules =
        userDoc.data()?['billRules'] as String? ?? ''; // Added billRules

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
                      pw.Text('Bill No: $sequentialBillNumber \n$billId',
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
                  // Product Rows with Comments
                  ..._products
                      .expand((product) => [
                            // Product details row
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(product.name),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(
                                      'Rs. ${product.price.toStringAsFixed(2)}'),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text('${product.quantity}'),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(
                                      'Rs. ${(product.price * product.quantity).toStringAsFixed(2)}'),
                                ),
                              ],
                            ),
                            // Comment row (only if comment exists)
                            if (product.comment != null &&
                                product.comment!
                                    .isNotEmpty) // Check if comment exists and is not empty
                              pw.TableRow(
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8),
                                    child:
                                        pw.Text('Comment: ${product.comment}',
                                            style: pw.TextStyle(
                                              fontSize: 10,
                                              fontStyle: pw.FontStyle.italic,
                                            )),
                                  ),
                                  pw.SizedBox(), // Empty cell for price
                                  pw.SizedBox(), // Empty cell for quantity
                                  pw.SizedBox(), // Empty cell for total
                                ],
                              ),
                          ])
                      .toList(),
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
                        pw.Text('Rs. ${totalAmount.toStringAsFixed(2)}',
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
                          pw.Text('Rs. ${_paidAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Balance: '),
                          pw.Text(
                              'Rs. ${(totalAmount - _paidAmount).toStringAsFixed(2)}'),
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
                      if (billRules.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('Terms & Conditions:',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(billRules,
                            style: const pw.TextStyle(fontSize: 8)),
                      ],
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

// Helper function to get signature image from URL and get it
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
            // Example of how to call it in your code
            ElevatedButton(
              onPressed: () async {
                String? filePath = await _downloadPDF('your-pdf-url-here');
                if (filePath != null) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF downloaded successfully')),
                  );
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to download PDF')),
                  );
                }
              },
              child: Text('Download PDF'),
            ),
            // TextButton(
            //   onPressed: () {
            //     // Implement download functionality
            //     _downloadPDF(pdfPath);
            //     Navigator.of(context).pop();
            //   },
            //   child: const Text('Download PDF'),
            // ),
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

  static Future<String?> _downloadPDF(String pdfUrl) async {
    try {
      print('Starting PDF download from: $pdfUrl'); // Debug log

      // Request storage permission on Android
      if (Platform.isAndroid) {
        print('Requesting Android storage permission...');
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          print('Storage permission denied');
          throw Exception('Storage permission denied');
        }
        print('Storage permission granted');
      }

      // Get storage directory
      Directory? directory;
      if (Platform.isAndroid) {
        var androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 30) {
          directory = await getExternalStorageDirectory();
        } else {
          directory = Directory('/storage/emulated/0/Download');
        }

        // Null check and directory existence check
        if (directory != null && !(await directory.exists())) {
          print(
              'Downloads directory not accessible, falling back to app storage');
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      // Ensure directory is not null
      if (directory == null) {
        print('Failed to get storage directory');
        throw Exception('Could not access storage directory');
      }

      // Ensure the directory exists
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      print('Using directory: ${directory.path}');

      // Create filename with timestamp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filename = 'invoice_$timestamp.pdf';
      String saveFilePath = '${directory.path}/$filename';

      print('Will save file to: $saveFilePath');

      // Download PDF
      print('Starting HTTP request...');
      final response = await http.get(Uri.parse(pdfUrl)).timeout(
        Duration(minutes: 2), // 2 minutes timeout
        onTimeout: () {
          print('Download timeout');
          throw Exception('Download timeout');
        },
      );

      print('HTTP Response status code: ${response.statusCode}');
      print('Response content length: ${response.contentLength}');

      if (response.statusCode == 200) {
        // Verify we received PDF data
        if (response.headers['content-type']?.contains('application/pdf') ==
                true ||
            response.bodyBytes.length > 0) {
          // Create and write to file
          File file = File(saveFilePath);
          await file.writeAsBytes(response.bodyBytes);

          // Verify file was created
          if (await file.exists()) {
            print('File successfully saved to: $saveFilePath');
            return saveFilePath;
          } else {
            print('File was not created');
            throw Exception('File was not created');
          }
        } else {
          print('Invalid PDF data received');
          throw Exception('Invalid PDF data received');
        }
      } else {
        print('HTTP request failed with status: ${response.statusCode}');
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error downloading PDF: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<bool> verifyFileExists(String filePath) async {
    return await File(filePath).exists();
  }

// Example usage:
  void downloadInvoice(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      String? filePath = await _downloadPDF(
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf');

      // Hide loading indicator
      Navigator.pop(context);

      if (filePath != null && await verifyFileExists(filePath)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded successfully to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF. Please check the logs.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
  final String? comment;

  ProductItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      if (comment != null) 'comment': comment,
    };
  }
}

// Future<String> _generateAndSharePDF(String billId) async {
//   // Get the next sequential bill number
//   final sequentialBillNumber = await _getNextBillNumber();

//   // Create a PDF document
//   final pdf = pw.Document();

//   // Fetch additional business details from Firestore
//   final user = FirebaseAuth.instance.currentUser;
//   final userDoc =
//       await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

//   // ... [rest of your existing code remains the same until the Bill Details section]

//   // Update the Bill Details section to use the sequential number
//   pw.Row(
//     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//     children: [
//       pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text('Bill No: $sequentialBillNumber',
//               style: const pw.TextStyle(fontSize: 12)),
//           pw.Text(
//               'Date: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
//               style: const pw.TextStyle(fontSize: 12)),
//         ],
//       ),
//       // ... [rest of your existing code remains the same]
//     ],
//   );

//   // ... [rest of your existing code remains the same]
// }
