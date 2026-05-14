import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/incomplete_transac_bloc/incomplete_transactions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/incomplete_transac_bloc/incomplete_transactions_state.dart';
import 'package:inventopos/presentation/transactions/widgets/signed_bill_preview_dialog.dart';
import 'package:inventopos/presentation/transactions/widgets/transaction_amount_row.dart';
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
                return Scaffold(
                  appBar: AppBar(
                    title: txState.isSearching
                        ? _buildSearchField(blocContext)
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Pending Transactions',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                    actions: [
                      IconButton(
                        icon: Icon(
                            txState.isSearching ? Icons.close : Icons.search),
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
                        icon: const Icon(Icons.calendar_today),
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
                  ),
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

                      if (txState.bills.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final partialRows = txState.bills
                          .where((b) => b.paymentStatus == 'partial')
                          .toList();

                      if (partialRows.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No pending payments',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final filteredBills = partialRows.where((bill) {
                        final customerName = bill.customerName;
                        return customerName
                            .toLowerCase()
                            .contains(txState.searchQuery);
                      }).toList();

                      final dateFilteredBills = txState.selectedDate != null
                          ? filteredBills.where((bill) {
                              final createdAt = bill.createdAt;
                              return DateFormat('yyyy-MM-dd')
                                      .format(createdAt) ==
                                  DateFormat('yyyy-MM-dd')
                                      .format(txState.selectedDate!);
                            }).toList()
                          : filteredBills;

                      final Map<String, List<Bill>> groupedBills = {};
                      for (final bill in dateFilteredBills) {
                        final date =
                            DateFormat('yyyy-MM-dd').format(bill.createdAt);
                        groupedBills.putIfAbsent(date, () => []);
                        groupedBills[date]!.add(bill);
                      }

                      return ListView.builder(
                        itemCount: groupedBills.length,
                        itemBuilder: (context, index) {
                          final date = groupedBills.keys.elementAt(index);
                          final bills = groupedBills[date]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  DateFormat('MMMM dd, yyyy')
                                      .format(DateTime.parse(date)),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...bills.map((bill) {
                                return _buildBillCard(context, bill);
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

  Future<void> _updateSignedBill(String billId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    if (!mounted) return;
    context.read<TransactionBillActionsBloc>().add(
          TransactionBillReplaceSignedRequested(
            billId: billId,
            localFilePath: image.path,
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
    BuildContext dialogHost,
    String billId,
    double remainingAmount,
    Bill bill,
  ) async {
    final amountController = TextEditingController();
    var updateSignedBill = false;

    await showDialog<void>(
      context: dialogHost,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            remainingAmount <= 0 ? 'Update Final Payment' : 'Update Payment',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Remaining Amount: ₹${remainingAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (double.tryParse(amountController.text) == remainingAmount)
                CheckboxListTile(
                  title: const Text('Update signed bill'),
                  value: updateSignedBill,
                  onChanged: (bool? value) {
                    setState(() {
                      updateSignedBill = value ?? false;
                    });
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0 || amount > remainingAmount) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }

                final newPaid = bill.paidAmount + amount;
                try {
                  await dialogContext.read<UpdateBillPaymentUseCase>().call(
                        billId: billId,
                        newPaidAmount: newPaid,
                        totalAmount: bill.totalAmount,
                      );
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                  return;
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (amount == remainingAmount && updateSignedBill) {
                  if (!mounted) return;
                  await _updateSignedBill(billId);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, Bill bill) {
    final billId = bill.id;
    final totalAmount = bill.totalAmount;
    final paidAmount = bill.paidAmount;
    final remainingAmount = totalAmount - paidAmount;
    final signedBillUrl = bill.signedBillUrl;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text(bill.customerName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Phone: ${bill.customerPhone.isEmpty ? 'N/A' : bill.customerPhone}'),
                TransactionAmountRow(
                  label: 'Total Amount:',
                  amount: totalAmount,
                ),
                TransactionAmountRow(
                  label: 'Amount Paid:',
                  amount: paidAmount,
                ),
                TransactionAmountRow(
                  label: 'Remaining Amount:',
                  amount: remainingAmount,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Update Signed Bill'),
                  onPressed: () => _updateSignedBill(billId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Show Bill'),
                  onPressed: signedBillUrl == null
                      ? null
                      : () => showSignedBillPreviewDialog(
                            context,
                            billUrl: signedBillUrl,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: remainingAmount > 0
                      ? () => _showUpdatePaymentDialog(
                            context,
                            billId,
                            remainingAmount,
                            bill,
                          )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
