import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_date_section_header.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/presentation/transactions/widgets/pending_transaction_bill_card.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/application/billing/delete_bill_use_case.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/billing/replace_signed_bill_use_case.dart';
import 'package:inventopos/application/billing/sync_overdue_partial_bill_notifications_use_case.dart';
import 'package:inventopos/application/billing/update_bill_payment_use_case.dart';
import 'package:inventopos/core/utils/date_picker_utils.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/incomplete_transac_bloc/incomplete_transactions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/incomplete_transac_bloc/incomplete_transactions_state.dart';
import 'package:inventopos/presentation/transactions/widgets/bill_pdf_viewer_page.dart';
import 'package:inventopos/presentation/transactions/widgets/transaction_bill_actions_feedback_listener.dart';

class IncompleteTransactionsScreen extends StatefulWidget {
  const IncompleteTransactionsScreen({super.key});

  @override
  State<IncompleteTransactionsScreen> createState() =>
      _IncompleteTransactionsScreenState();
}

class _IncompleteTransactionsScreenState
    extends State<IncompleteTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => IncompleteTransactionsBloc(
            context.read<ObserveBillsUseCase>(),
            context.read<SyncOverduePartialBillNotificationsUseCase>(),
            context.read<AuthRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => TransactionBillActionsBloc(
            replaceSignedBill: context.read<ReplaceSignedBillUseCase>(),
            deleteBill: context.read<DeleteBillUseCase>(),
          ),
        ),
      ],
      child: Builder(
        builder: (blocContext) {
          return TransactionBillActionsFeedbackListener(
            child: BlocBuilder<IncompleteTransactionsBloc,
                IncompleteTransactionsViewState>(
              builder: (context, txState) {
                return AppScreenScaffold(
                  title: txState.isSearching ? null : 'Pending Transactions',
                  titleWidget:
                      txState.isSearching ? _buildSearchField(blocContext) : null,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        txState.isSearching ? Icons.close : Icons.search,
                      ),
                      onPressed: () {
                        if (txState.isSearching) {
                          _searchController.clear();
                        }
                        blocContext
                            .read<IncompleteTransactionsBloc>()
                            .toggleSearchMode();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () async {
                          final lastSelectable = DateTime.now();
                          final firstSelectable = DateTime(2000);
                          final pickedDate = await showDatePicker(
                            context: blocContext,
                            initialDate: DatePickerUtils.clampInitial(
                              preferred: txState.selectedDate,
                              fallback: lastSelectable,
                              first: firstSelectable,
                              last: lastSelectable,
                            ),
                            firstDate: firstSelectable,
                            lastDate: lastSelectable,
                          );

                          if (pickedDate != null) {
                            if (!blocContext.mounted) return;
                            blocContext
                                .read<IncompleteTransactionsBloc>()
                                .setSelectedDate(pickedDate);
                          }
                        },
                      ),
                  ],
                  body: Builder(
                    builder: (bodyContext) {
                      final session =
                          bodyContext.read<AuthRepository>().currentSession;
                      if (session == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Please login to view transactions'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  bodyContext.go('/login');
                                },
                                child: const Text('Go to Login'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (txState.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!txState.hasPartialBills) {
                        return const AppEmptyState(
                          icon: Icons.pending_actions_outlined,
                          title: 'No pending payments',
                          message:
                              'Partially paid bills will appear here until fully settled.',
                        );
                      }

                      final groupedBills = txState.groupedTransactions;

                      return ListView.builder(
                        itemCount: groupedBills.length,
                        itemBuilder: (context, index) {
                          final date = groupedBills.keys.elementAt(index);
                          final bills = groupedBills[date]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppDateSectionHeader(
                                label: DateFormat('MMMM dd, yyyy')
                                    .format(DateTime.parse(date)),
                              ),
                              ...bills.map((bill) {
                                final remaining =
                                    bill.totalAmount - bill.paidAmount;
                                return PendingTransactionBillCard(
                                  bill: bill,
                                  onUpdatePayment: remaining > 0
                                      ? () => _showUpdatePaymentDialog(
                                            bodyContext,
                                            bill.id,
                                            remaining,
                                            bill,
                                          )
                                      : () {},
                                  onShowBill: () =>
                                      openBillPdfForBill(bodyContext, bill),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(BuildContext blocContext) {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Search by customer name...',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        blocContext
            .read<IncompleteTransactionsBloc>()
            .setSearchQuery(value.toLowerCase());
      },
    );
  }

  Future<void> _showUpdatePaymentDialog(
    BuildContext scaffoldContext,
    String billId,
    double remainingAmount,
    Bill bill,
  ) async {
    await showDialog<void>(
      context: scaffoldContext,
      barrierDismissible: false,
      builder: (dialogContext) => _UpdatePaymentDialog(
        billId: billId,
        bill: bill,
        remainingAmount: remainingAmount,
        scaffoldContext: scaffoldContext,
      ),
    );
  }

}

class _UpdatePaymentDialog extends StatefulWidget {
  const _UpdatePaymentDialog({
    required this.billId,
    required this.bill,
    required this.remainingAmount,
    required this.scaffoldContext,
  });

  final String billId;
  final Bill bill;
  final double remainingAmount;
  final BuildContext scaffoldContext;

  @override
  State<_UpdatePaymentDialog> createState() => _UpdatePaymentDialogState();
}

class _UpdatePaymentDialogState extends State<_UpdatePaymentDialog> {
  final _amountController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || amount > widget.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    final newPaid = widget.bill.paidAmount + amount;
    UpdateBillPaymentResult result;
    try {
      result = await context.read<UpdateBillPaymentUseCase>().call(
            billId: widget.billId,
            newPaidAmount: newPaid,
            totalAmount: widget.bill.totalAmount,
          );
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    _showResultSnackBar(result);
    if (mounted) Navigator.pop(context);
  }

  void _showResultSnackBar(UpdateBillPaymentResult result) {
    final host = widget.scaffoldContext;
    if (!host.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(host);
    if (messenger == null) return;

    if (result.pdfSyncFailed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Payment updated. Invoice PDF could not sync to cloud — '
            'tap Show Bill to retry.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment and invoice updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isUpdating,
      child: AlertDialog(
        title: Text(_isUpdating ? 'Processing payment' : 'Update payment'),
        content: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _isUpdating
              ? _UpdatePaymentLoader(theme: theme)
              : _UpdatePaymentForm(
                  key: const ValueKey('form'),
                  remainingAmount: widget.remainingAmount,
                  amountController: _amountController,
                ),
        ),
        actions: _isUpdating
            ? null
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Update'),
                ),
              ],
      ),
    );
  }
}

class _UpdatePaymentForm extends StatelessWidget {
  const _UpdatePaymentForm({
    super.key,
    required this.remainingAmount,
    required this.amountController,
  });

  final double remainingAmount;
  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('form-column'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Remaining: ₹${remainingAmount.toStringAsFixed(2)}'),
        const SizedBox(height: 16),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount paid now',
            border: OutlineInputBorder(),
            prefixText: '₹',
          ),
        ),
      ],
    );
  }
}

class _UpdatePaymentLoader extends StatelessWidget {
  const _UpdatePaymentLoader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('loader'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 96,
          width: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 96,
                width: 96,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: theme.colorScheme.primary,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payments_rounded,
                  size: 28,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Updating payment…',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        )
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.15, end: 0, duration: 280.ms),
        const SizedBox(height: 8),
        Text(
          'Syncing your invoice PDF',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 120.ms, duration: 320.ms)
            .slideY(begin: 0.12, end: 0, delay: 120.ms, duration: 320.ms),
      ],
    );
  }
}
