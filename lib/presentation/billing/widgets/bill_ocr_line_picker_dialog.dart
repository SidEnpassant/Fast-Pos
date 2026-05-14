import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/application/billing/extract_text_lines_from_image_path_use_case.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> showOcrLinePickerDialog(
  BuildContext context, {
  required ImagePicker imagePicker,
  required ExtractTextLinesFromImagePathUseCase extractLines,
}) async {
  final status = await Permission.camera.request();
  if (status.isDenied) {
    return null;
  }
  if (!context.mounted) {
    return null;
  }

  final image = await imagePicker.pickImage(source: ImageSource.camera);
  if (image == null) return null;

  final ocrLines = await extractLines(image.path);

  if (!context.mounted) return null;

  final selectedTexts = <String>{};

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
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
                                  .map(
                                    (text) => Chip(
                                      label: Text(text),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: () {
                                        setState(() {
                                          selectedTexts.remove(text);
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ...ocrLines.map(
                      (line) => InkWell(
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
                          margin: const EdgeInsets.symmetric(vertical: 4),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedTexts.isEmpty
                ? null
                : () {
                    final combinedText = selectedTexts.join(' ');
                    Navigator.pop(dialogContext, combinedText);
                  },
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}
