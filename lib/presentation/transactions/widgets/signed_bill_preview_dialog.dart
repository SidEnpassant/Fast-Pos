import 'package:flutter/material.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';

Future<void> showSignedBillPreviewDialog(
  BuildContext context, {
  required String billUrl,
}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        child: Container(
          width: MediaQuery.of(dialogContext).size.width * 0.9,
          height: MediaQuery.of(dialogContext).size.height * 0.7,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () {
                      Navigator.of(dialogContext).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) => Scaffold(
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              iconTheme:
                                  const IconThemeData(color: Colors.white),
                            ),
                            backgroundColor: Colors.black,
                            body: Center(
                              child: Image.network(
                                billUrl,
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const AppShimmer(
                                    child: Center(
                                      child: Icon(Icons.image,
                                          size: 100, color: Colors.white),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text(
                                      'Error loading image',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              Expanded(
                child: Image.network(
                  billUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const AppShimmer(
                      child: Center(
                        child:
                            Icon(Icons.image, size: 200, color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Error loading image'));
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
