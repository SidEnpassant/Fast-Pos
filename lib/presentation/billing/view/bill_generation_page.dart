import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/application/billing/extract_text_lines_from_image_path_use_case.dart';
import 'package:inventopos/application/billing/lookup_product_name_by_barcode_use_case.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/billing/bill_submission.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_state.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_state.dart';
import 'package:inventopos/presentation/billing/widgets/bill_generation_sections.dart';
import 'package:inventopos/presentation/billing/widgets/bill_invoice_download_demo.dart';
import 'package:inventopos/presentation/billing/widgets/bill_submission_feedback_listener.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';

class BillGenerationPage extends StatefulWidget {
  const BillGenerationPage({super.key});

  @override
  State<BillGenerationPage> createState() => _BillGenerationPageState();
}

class _BillGenerationPageState extends State<BillGenerationPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  String _paymentMethod = 'cash';
  String _paymentStatus = 'complete';
  double _paidAmount = 0.0;
  SpeechToText _speech = SpeechToText();

  bool _isListening = false;
  String _voiceInputText = '';

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BillSubmissionFeedbackListener(
      onSuccess: (listenerContext, submissionState) {
        listenerContext.read<BillDraftBloc>().add(const BillDraftCleared());
        _customerNameController.clear();
        _customerPhoneController.clear();
        _showPDFOptionsDialog(submissionState.result.pdfPath);
      },
      child: BlocBuilder<BillDraftBloc, BillDraftState>(
        builder: (context, draft) {
          final totalAmount = draft.subtotal;
          final submitting = context.watch<BillSubmissionBloc>().state
              is BillSubmissionLoading;

          return Material(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBar(
                  title: Text(
                    'Generate Bill',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.white,
                  centerTitle: true,
                ),
                Expanded(
                  child: submitting
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
                              BillGenerationCustomerSection(
                                nameController: _customerNameController,
                                phoneController: _customerPhoneController,
                                isListening: _isListening,
                                onMicPressed: _listen,
                              ),
                              const SizedBox(height: 16),
                              BillGenerationProductsSection(
                                lines: draft.lines,
                                totalAmount: totalAmount,
                                onAddProduct: _showAddProductDialog,
                              ),
                              const SizedBox(height: 16),
                              BillGenerationPaymentSection(
                                paymentMethod: _paymentMethod,
                                paymentStatus: _paymentStatus,
                                paidAmount: _paidAmount,
                                totalAmount: totalAmount,
                                onPaymentMethodChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _paymentMethod = v);
                                },
                                onPaymentStatusChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _paymentStatus = v;
                                    if (v == 'complete') {
                                      _paidAmount = totalAmount;
                                    }
                                  });
                                },
                                onPaidAmountChanged: (d) =>
                                    setState(() => _paidAmount = d),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: (draft.lines.isEmpty || submitting)
                                    ? null
                                    : _generateBill,
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
                              ).animate().fadeIn().slideY(
                                  delay: const Duration(milliseconds: 600)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
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

  Future<void> _showAddProductDialog([String? initialProductName]) async {
    final nameController = TextEditingController(text: initialProductName);
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final commentController = TextEditingController();
    final speechToText = SpeechToText();
    bool isListening = false;
    final draftBloc = context.read<BillDraftBloc>();

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
                          bool available = await speechToText.initialize();
                          if (available) {
                            setDialogState(() => isListening = true);
                            speechToText.listen(
                              onResult: (result) {
                                setDialogState(() {
                                  commentController.text =
                                      result.recognizedWords;
                                });
                              },
                              listenFor: const Duration(seconds: 30),
                              pauseFor: const Duration(seconds: 5),
                              listenOptions: SpeechListenOptions(
                                partialResults: true,
                                cancelOnError: true,
                                listenMode: ListenMode.confirmation,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() => isListening = false);
                          speechToText.stop();
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
                  Navigator.pop(context);
                  draftBloc.add(
                    BillDraftLineAdded(
                      BillDraftLine(
                        name: name,
                        price: price,
                        quantity: quantity,
                        comment: comment.isNotEmpty ? comment : null,
                      ),
                    ),
                  );
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
    final lookup = context.read<LookupProductNameByBarcodeUseCase>();
    final status = await Permission.camera.request();
    if (status.isDenied) {
      return null;
    }
    if (!mounted) {
      return null;
    }

    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text('Scan Barcode'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) async {
                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;
                      final barcode = barcodes.first.rawValue;
                      try {
                        final name = await lookup(barcode);
                        if (name != null && sheetContext.mounted) {
                          Navigator.pop(sheetContext, name);
                        } else {
                          debugPrint(
                            'Product not found or error in response.',
                          );
                        }
                      } catch (e) {
                        debugPrint('Error looking up product: $e');
                      }
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
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
  }

  Future<String?> _showTextRecognition() async {
    final extractLines = context.read<ExtractTextLinesFromImagePathUseCase>();
    final status = await Permission.camera.request();
    if (status.isDenied) {
      return null;
    }

    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final ocrLines = await extractLines(image.path);

    if (!mounted) return null;

    final Set<String> selectedTexts = {};

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
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
                      ...ocrLines.map((line) => InkWell(
                            onTap: () {
                              setState(() {
                                if (selectedTexts.contains(line)) {
                                  selectedTexts.remove(line);
                                } else {
                                  selectedTexts.add(line);
                                }
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedTexts.contains(line)
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : null,
                                border: Border.all(
                                  color: selectedTexts.contains(line)
                                      ? Colors.blue
                                      : Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selectedTexts.contains(line)
                                      ? Colors.blue
                                      : null,
                                ),
                              ),
                            ),
                          )),
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
    final draftLines = context.read<BillDraftBloc>().state.lines;
    if (draftLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    context.read<BillSubmissionBloc>().add(
          BillSubmissionRequested(
            BillSubmissionDraft(
              customerName: _customerNameController.text.trim(),
              customerPhone: _customerPhoneController.text.trim(),
              lines: draftLines,
              paymentMethod: _paymentMethod,
              paymentStatus: _paymentStatus,
              paidAmount: _paidAmount,
            ),
          ),
        );
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
            // ElevatedButton(
            //   onPressed: () async {
            //     String? filePath = await _downloadPDF('your-pdf-url-here');
            //     if (filePath != null) {
            //       // Show success message
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text('PDF downloaded successfully')),
            //       );
            //     } else {
            //       // Show error message
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text('Failed to download PDF')),
            //       );
            //     }
            //   },
            //   child: Text('Download PDF'),
            // ),
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

  /// Sample remote PDF download (same behavior as before), delegated to
  /// [BillInvoiceDownloadDemo].
  void downloadInvoice(BuildContext context) {
    BillInvoiceDownloadDemo.runSampleDownload(context);
  }

  Future<void> _viewPDF(String pdfPath) async {
    try {
      // Open the PDF using the Open File package
      final result = await OpenFile.open(pdfPath);
      if (result.type == ResultType.error) {
        debugPrint('Error opening PDF: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error viewing PDF: $e');
    }
  }

  Future<void> _sharePDF(String pdfPath) async {
    try {
      final xFile = XFile(pdfPath);
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Here is your bill.',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }
}
