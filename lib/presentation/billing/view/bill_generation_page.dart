import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
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
import 'package:inventopos/domain/repositories/product_repository.dart';
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
    final theme = Theme.of(context);

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
              return Scaffold(
                backgroundColor: theme.colorScheme.surfaceContainerLowest,
                body: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header matching dashboard style ──
                      _BillHeader(
                        lineCount: draft.lines.length,
                        totalAmount: totalAmount,
                      ),
                      // ── Content ──
                      Expanded(
                        child: submitting
                            ? _SubmittingIndicator()
                            : Form(
                                key: _formKey,
                                child: CustomScrollView(
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      sliver: SliverList(
                                        delegate: SliverChildListDelegate([
                                          BillGenerationCustomerSection(
                                            nameController:
                                                _customerNameController,
                                            phoneController:
                                                _customerPhoneController,
                                            isListening: voice.isListening,
                                            onMicPressed: () => context
                                                .read<BillVoiceAssistBloc>()
                                                .add(
                                                  const BillVoiceAssistTogglePressed(),
                                                ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.md,
                                          ),
                                          BillGenerationProductsSection(
                                            lines: draft.lines,
                                            totalAmount: totalAmount,
                                            onAddProduct:
                                                _showAddProductChooser,
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.md,
                                          ),
                                          BillGenerationPaymentSection(
                                            paymentMethod: _paymentMethod,
                                            paymentStatus: _paymentStatus,
                                            paidAmount: _paidAmount,
                                            totalAmount: totalAmount,
                                            onPaymentMethodChanged: (v) {
                                              if (v == null) return;
                                              setState(
                                                () => _paymentMethod = v,
                                              );
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
                                                setState(
                                              () => _paidAmount = d,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.lg,
                                          ),
                                          // ── Generate bill button ──
                                          _GenerateBillButton(
                                            enabled: draft.lines.isNotEmpty &&
                                                !submitting,
                                            onPressed: _generateBill,
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.lg,
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
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
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 40,
            ),
          ),
          title: const Text('Bill Generated!'),
          content: const Text(
            'Your bill has been created successfully. What would you like to do?',
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _printReceipt();
              },
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Print'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                _viewPDF(pdfPath);
                Navigator.of(dialogContext).pop();
              },
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('View'),
            ),
            FilledButton.icon(
              onPressed: () {
                _sharePDF(pdfPath);
                Navigator.of(dialogContext).pop();
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printReceipt() async {
    final draft = context.read<BillDraftBloc>().state;
    final profile = await context
        .read<ProfileRepository>()
        .fetchCurrentUserProfileSnapshot();
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

// ─── Header ─────────────────────────────────────────────────────────────────

class _BillHeader extends StatelessWidget {
  const _BillHeader({
    required this.lineCount,
    required this.totalAmount,
  });

  final int lineCount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Bill',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  lineCount == 0
                      ? 'Add products to get started'
                      : '$lineCount item${lineCount == 1 ? '' : 's'} added',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (lineCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                '₹${totalAmount.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Submitting indicator ───────────────────────────────────────────────────

class _SubmittingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Generating Bill…',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Creating invoice, updating inventory',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generate bill button ───────────────────────────────────────────────────

class _GenerateBillButton extends StatelessWidget {
  const _GenerateBillButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.receipt_long),
      label: const Text('Generate Bill'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ).animate().fadeIn().slideY(
          delay: const Duration(milliseconds: 600),
        );
  }
}
