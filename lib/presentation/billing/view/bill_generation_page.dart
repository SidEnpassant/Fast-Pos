import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/billing/print_receipt_use_case.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/domain/billing/bill_submission.dart';
import 'package:inventopos/domain/entities/receipt_payload.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';
import 'package:inventopos/domain/repositories/customer_repository.dart';
import 'package:inventopos/domain/repositories/loyalty_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/bill_sanity/bloc/bill_sanity_check_bloc.dart';
import 'package:inventopos/presentation/bill_sanity/bloc/bill_sanity_check_event.dart';
import 'package:inventopos/presentation/bill_sanity/bloc/bill_sanity_check_state.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_state.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_state.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_state.dart';
import 'package:inventopos/presentation/billing/bloc/receipt_automation_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/repeat_order_bloc.dart';
import 'package:inventopos/presentation/billing/widgets/bill_add_product_chooser.dart';
import 'package:inventopos/presentation/billing/widgets/bill_generation_sections.dart';
import 'package:inventopos/presentation/billing/widgets/bill_submission_feedback_listener.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_bloc.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_event.dart';
import 'package:inventopos/presentation/checkout/bloc/checkout_state.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_bloc.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_event.dart';
import 'package:inventopos/presentation/messaging/widgets/message_preview_sheet.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  void initState() {
    super.initState();
    _customerPhoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final phone = _customerPhoneController.text.trim();
    if (phone.length == 10) {
      _resolveCustomerByPhone(phone);
    } else {
      context.read<CheckoutBloc>().add(
            const CheckoutPointsUpdated(
              points: 0,
              currencyPerPoint: 0.0,
            ),
          );
    }
  }

  Future<void> _resolveCustomerByPhone(String phone) async {
    final dashboardState = context.read<DashboardHubBloc>().state;
    final bills = dashboardState.bills ?? [];

    // Optional: trigger repeat order if past bill found
    final bill = bills.where((b) => b.customerPhone == phone).firstOrNull;
    if (bill?.customerId != null) {
      context.read<RepeatOrderBloc>().add(
            RepeatOrderStarted(customerId: bill!.customerId!, bills: bills),
          );
    }

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final customer = await context.read<CustomerRepository>().findByPhone(uid, phone);
      if (customer != null && mounted) {
        _fetchCustomerLoyalty(customer.id);
      }
    } catch (e) {
      debugPrint('Error finding customer by phone: $e');
    }
  }

  Future<void> _fetchCustomerLoyalty(String customerId) async {
    try {
      final customer = await context.read<CustomerRepository>().findById(customerId);
      if (customer != null && mounted) {
        final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
        final loyaltyConfig = await context.read<LoyaltyRepository>().getLoyaltyConfig(uid);

        if (loyaltyConfig.isEnabled && mounted) {
          context.read<CheckoutBloc>().add(
                CheckoutPointsUpdated(
                  points: customer.loyaltyPoints,
                  currencyPerPoint: loyaltyConfig.currencyUnitPerPoint,
                ),
              );
        }
      }
    } catch (e) {
      debugPrint('Error fetching loyalty: $e');
    }
  }

  @override
  void dispose() {
    _customerPhoneController.removeListener(_onPhoneChanged);
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _showAddProductChooser() => showBillAddProductChooser(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BillSubmissionFeedbackListener(
          onSuccess: (listenerContext, submissionState) async {
            final uid = Supabase.instance.client.auth.currentUser?.id ?? '';

            // Capture dependencies before async gap
            final prefsUseCase =
                listenerContext.read<ObserveAiPreferencesUseCase>();
            final profileUseCase =
                listenerContext.read<ObserveProfileForCurrentUserUseCase>();
            final receiptBloc = listenerContext.read<ReceiptAutomationBloc>();
            final draftBloc = listenerContext.read<BillDraftBloc>();

            final prefs = await prefsUseCase(uid).first;
            final profileStream = profileUseCase.call();
            List<UserProfile>? profileList;
            if (profileStream != null) {
              profileList = await profileStream.first;
            }

            String shopName = 'Our Shop';
            if (profileList != null && profileList.isNotEmpty) {
              shopName = profileList.first.businessName ?? 'Our Shop';
            }

            if (listenerContext.mounted) {
              receiptBloc.add(
                ReceiptAutomationSubmitted(
                  bill: submissionState.result.bill,
                  shopName: shopName,
                  prefs: prefs,
                ),
              );

              draftBloc.add(const BillDraftCleared());
              _customerNameController.clear();
              _customerPhoneController.clear();
              _showPDFOptionsDialog(submissionState.result.pdfPath);
            }
          },
        ),
        BlocListener<ReceiptAutomationBloc, ReceiptAutomationState>(
          listener: (context, state) {
            if (state.receiptMessage != null) {
              _showReceiptAutomationOptions(state);
            }
          },
        ),
        BlocListener<BillSanityCheckBloc, BillSanityCheckState>(
          listener: (context, state) {
            if (state.result != null && !state.overridden) {
              final checkout = context.read<CheckoutBloc>().state;
              _showSanityWarning(state.result!.message, checkout);
            }
          },
        ),
      ],
      child: BlocBuilder<BillDraftBloc, BillDraftState>(
        builder: (context, draft) {
          return BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, checkout) {
              final subtotal = draft.subtotal;
              final totalDiscount = checkout.totalDiscount;
              final totalAmount = (subtotal - totalDiscount).clamp(0.0, double.infinity);
              
              final submitting = context.select<BillSubmissionBloc, bool>(
                (bloc) => bloc.state is BillSubmissionLoading,
              );

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
                          _BillHeader(
                            lineCount: draft.lines.length,
                            totalAmount: totalAmount,
                          ),
                          Expanded(
                            child: submitting
                                ? const _SubmittingIndicator()
                                : Form(
                                    key: _formKey,
                                    child: CustomScrollView(
                                      slivers: [
                                        SliverPadding(
                                          padding: EdgeInsets.all(
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
                                              SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              BillGenerationProductsSection(
                                                lines: draft.lines,
                                                totalAmount: subtotal,
                                                onAddProduct:
                                                    _showAddProductChooser,
                                              ),
                                              SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              if (checkout.availablePoints > 0)
                                                _LoyaltyRedemptionCard(
                                                  checkoutState: checkout,
                                                  onToggle: (v) => context.read<CheckoutBloc>().add(
                                                    CheckoutLoyaltyRedemptionToggled(v),
                                                  ),
                                                ),
                                              if (checkout.availablePoints > 0)
                                                SizedBox(height: AppSpacing.md),
                                              _PaymentSection(
                                                totalAmount: totalAmount,
                                                onChanged: (method, status, paid) {
                                                  _paymentMethod = method;
                                                  _paymentStatus = status;
                                                  _paidAmount = paid;
                                                },
                                              ),
                                              SizedBox(
                                                height: AppSpacing.lg,
                                              ),
                                              _GenerateBillButton(
                                                enabled: draft.lines.isNotEmpty &&
                                                    !submitting,
                                                onPressed: () => _generateBill(checkout),
                                              ),
                                              SizedBox(
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
          );
        },
      ),
    );
  }

  Future<void> _generateBill(CheckoutState checkout) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You must be logged in.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    final draft = context.read<BillDraftBloc>().state;
    final draftLines = draft.lines;
    if (draftLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    final sanity = context.read<BillSanityCheckBloc>().state;
    if (sanity.result != null && !sanity.overridden) {
      context.read<BillSanityCheckBloc>().add(
            BillSanityCheckRequested(
              lines: draftLines,
              draftTotal: draft.subtotal,
              recentBills: context.read<DashboardHubBloc>().state.bills ?? [],
            ),
          );
      return;
    }

    String? customerId;
    final phone = _customerPhoneController.text.trim();
    if (phone.length == 10) {
      final bills = context.read<DashboardHubBloc>().state.bills ?? [];
      customerId = bills.where((b) => b.customerPhone == phone).firstOrNull?.customerId;
    }

    final breakdown = <Map<String, dynamic>>[];
    if (checkout.isLoyaltyRedemptionActive && checkout.loyaltyDiscount > 0) {
      breakdown.add({
        'type': 'loyalty',
        'points_redeemed': checkout.availablePoints,
        'amount': checkout.loyaltyDiscount,
      });
    }

    context.read<BillSubmissionBloc>().add(
          BillSubmissionRequested(
            BillSubmissionDraft(
              customerName: _customerNameController.text.trim(),
              customerPhone: _customerPhoneController.text.trim(),
              customerId: customerId,
              lines: draftLines,
              paymentMethod: _paymentMethod,
              paymentStatus: _paymentStatus,
              paidAmount: _paidAmount,
              discountTotal: checkout.totalDiscount,
              discountBreakdown: breakdown.isEmpty ? null : breakdown,
            ),
          ),
        );
  }

  void _showSanityWarning(String message, CheckoutState checkout) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bill Warning'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<BillSanityCheckBloc>()
                  .add(const BillSanityCheckOverrideConfirmed());
              _generateBill(checkout);
            },
            child: const Text('Proceed anyway'),
          ),
        ],
      ),
    );
  }

  void _showReceiptAutomationOptions(ReceiptAutomationState state) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Automations',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (state.receiptMessage != null)
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp Digital Receipt'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _launchMessaging(state.receiptMessage!);
                },
              ),
            if (state.thankYouMessage != null)
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.pink),
                title: const Text('Send Thank You Message'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _launchMessaging(state.thankYouMessage!);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchMessaging(OutboundMessage message) async {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final prefs = await context.read<ObserveAiPreferencesUseCase>()(uid).first;
    if (!mounted) return;
    context.read<MessagingAutomationBloc>().add(
          MessagingPreviewRequested(message, prefs),
        );
    showMessagePreviewSheet(context);
  }

  Future<void> _showPDFOptionsDialog(String pdfPath) {
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

class _PaymentSection extends StatefulWidget {
  const _PaymentSection({
    required this.totalAmount,
    required this.onChanged,
  });

  final double totalAmount;
  final void Function(String method, String status, double paid) onChanged;

  @override
  State<_PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<_PaymentSection> {
  String _method = 'cash';
  String _status = 'complete';
  late double _paid;

  @override
  void initState() {
    super.initState();
    _paid = widget.totalAmount;
  }

  @override
  void didUpdateWidget(_PaymentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount && _status == 'complete') {
      _paid = widget.totalAmount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(_method, _status, _paid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BillGenerationPaymentSection(
      paymentMethod: _method,
      paymentStatus: _status,
      paidAmount: _paid,
      totalAmount: widget.totalAmount,
      onPaymentMethodChanged: (v) {
        if (v == null) return;
        setState(() => _method = v);
        widget.onChanged(_method, _status, _paid);
      },
      onPaymentStatusChanged: (v) {
        if (v == null) return;
        setState(() {
          _status = v;
          if (v == 'complete') {
            _paid = widget.totalAmount;
          }
        });
        widget.onChanged(_method, _status, _paid);
      },
      onPaidAmountChanged: (d) {
        setState(() => _paid = d);
        widget.onChanged(_method, _status, _paid);
      },
    );
  }
}

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
      padding: EdgeInsets.fromLTRB(
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
              padding: EdgeInsets.symmetric(
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

class _SubmittingIndicator extends StatelessWidget {
  const _SubmittingIndicator();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppShimmer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Container(
              width: 150,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              width: 200,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _LoyaltyRedemptionCard extends StatelessWidget {
  const _LoyaltyRedemptionCard({
    required this.checkoutState,
    required this.onToggle,
  });

  final CheckoutState checkoutState;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pts = checkoutState.availablePoints;
    final discount = pts * checkoutState.currencyPerPoint;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: checkoutState.isLoyaltyRedemptionActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: checkoutState.isLoyaltyRedemptionActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars,
            color: checkoutState.isLoyaltyRedemptionActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loyalty Program',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$pts pts available (-₹${discount.toStringAsFixed(2)})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: checkoutState.isLoyaltyRedemptionActive,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
