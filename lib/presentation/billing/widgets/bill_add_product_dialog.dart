import 'package:flutter/material.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Presents the add-line dialog; [parentContext] must stay mounted for re-entry
/// after barcode/OCR flows.
Future<void> showAddBillProductDialog(
  BuildContext parentContext, {
  required BillDraftBloc draftBloc,
  required Future<String?> Function() pickBarcodeProductName,
  required Future<String?> Function() pickOcrCombinedText,
  String? initialProductName,
}) async {
  final nameController = TextEditingController(text: initialProductName);
  final priceController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final commentController = TextEditingController();
  final speechToText = SpeechToText();
  var isListening = false;

  try {
    await showDialog<void>(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
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
                              Navigator.pop(dialogContext);
                              final scannedName = await pickBarcodeProductName();
                              if (scannedName != null && parentContext.mounted) {
                                await showAddBillProductDialog(
                                  parentContext,
                                  draftBloc: draftBloc,
                                  pickBarcodeProductName: pickBarcodeProductName,
                                  pickOcrCombinedText: pickOcrCombinedText,
                                  initialProductName: scannedName,
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              final recognized = await pickOcrCombinedText();
                              if (recognized != null && parentContext.mounted) {
                                await showAddBillProductDialog(
                                  parentContext,
                                  draftBloc: draftBloc,
                                  pickBarcodeProductName: pickBarcodeProductName,
                                  pickOcrCombinedText: pickOcrCombinedText,
                                  initialProductName: recognized,
                                );
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
                            final available = await speechToText.initialize();
                            if (available) {
                              setDialogState(() {
                                isListening = true;
                              });
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
                            setDialogState(() {
                              isListening = false;
                            });
                            await speechToText.stop();
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
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text) ?? 0;
                  final quantity = int.tryParse(quantityController.text) ?? 0;
                  final comment = commentController.text.trim();

                  if (name.isNotEmpty && price > 0 && quantity > 0) {
                    Navigator.pop(dialogContext);
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
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fill in all required fields correctly',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    commentController.dispose();
    if (isListening) {
      await speechToText.stop();
    }
  }
}
