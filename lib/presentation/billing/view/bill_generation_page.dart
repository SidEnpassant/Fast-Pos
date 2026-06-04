import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/presentation/billing/widgets/bill_add_product_chooser.dart';
import 'package:inventopos/domain/billing/bill_submission.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_state.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_state.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_state.dart';
import 'package:inventopos/presentation/billing/widgets/bill_generation_sections.dart';
import 'package:inventopos/application/billing/print_receipt_use_case.dart';
import 'package:inventopos/domain/entities/receipt_payload.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/presentation/billing_copilot/widgets/billing_copilot_sheet.dart';
import 'package:inventopos/presentation/billing/widgets/bill_submission_feedback_listener.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class BillGenerationPage extends StatefulWidget {
  const BillGenerationPage({super.key});

  @override
  State<BillGenerationPage> createState() => _BillGenerationPageState();
}

class _BillGenerationPageState extends State<BillGenerationPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  String _paymentMethod = 'cash';
  String _paymentStatus = 'complete';
  double _paidAmount = 0.0;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _showAddProductChooser() => showBillAddProductChooser(context);

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

          return BlocConsumer<BillVoiceAssistBloc, BillVoiceAssistState>(
            listenWhen: (previous, current) =>
                current.isListening &&
                current.transcript != previous.transcript,
            listener: (context, state) {
              if (state.transcript.isNotEmpty) {
                _customerNameController.text = state.transcript;
              }
            },
            builder: (context, voice) {
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
                      // actions: [
                      //   IconButton(
                      //     tooltip: 'Billing Copilot',
                      //     icon: const Icon(Icons.smart_toy_outlined),
                      //     onPressed: () async {
                      //       final uid = context
                      //           .read<AuthRepository>()
                      //           .currentSession
                      //           ?.userId;
                      //       if (uid == null) return;
                      //       final products = await context
                      //           .read<ProductRepository>()
                      //           .fetchProductsForUser(uid);
                      //       if (!context.mounted) return;
                      //       showBillingCopilotSheet(
                      //         context,
                      //         userId: uid,
                      //         products: products,
                      //       );
                      //     },
                      //   ),
                      // ],
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
                                    isListening: voice.isListening,
                                    onMicPressed: () =>
                                        context.read<BillVoiceAssistBloc>().add(
                                              const BillVoiceAssistTogglePressed(),
                                            ),
                                  ),
                                  const SizedBox(height: 16),
                                  BillGenerationProductsSection(
                                    lines: draft.lines,
                                    totalAmount: totalAmount,
                                    onAddProduct: _showAddProductChooser,
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
                                    onPressed:
                                        (draft.lines.isEmpty || submitting)
                                            ? null
                                            : _generateBill,
                                    icon: const Icon(Icons.receipt_long),
                                    label: Text(
                                      'Generate Bill',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
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
                                        delay: const Duration(
                                          milliseconds: 600,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _printReceipt();
              },
              child: const Text('Print receipt'),
            ),
            TextButton(
              onPressed: () {
                _viewPDF(pdfPath);
                Navigator.of(context).pop();
              },
              child: const Text('View PDF'),
            ),
            TextButton(
              onPressed: () {
                _sharePDF(pdfPath);
                Navigator.of(context).pop();
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printReceipt() async {
    final draft = context.read<BillDraftBloc>().state;
    final profile = await context.read<ProfileRepository>().fetchCurrentUserProfileSnapshot();
    final business = profile?.businessName ?? 'Business';
    try {
      await context.read<PrintReceiptUseCase>().call(
            ReceiptPayload(
              businessName: business,
              customerName: _customerNameController.text.trim(),
              lines: draft.lines
                  .map(
                    (l) => ReceiptLine(
                      name: l.name,
                      quantity: l.quantity,
                      total: l.price * l.quantity,
                    ),
                  )
                  .toList(),
              totalAmount: draft.subtotal,
              paidAmount: _paidAmount,
              paymentMethod: _paymentMethod,
            ),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _viewPDF(String pdfPath) async {
    try {
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
