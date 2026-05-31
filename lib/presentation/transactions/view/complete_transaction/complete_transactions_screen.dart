import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/application/billing/delete_bill_use_case.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/application/billing/replace_signed_bill_use_case.dart';
import 'package:inventopos/core/utils/date_picker_utils.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_state.dart';
import 'package:inventopos/presentation/transactions/widgets/bill_pdf_viewer_page.dart';
import 'package:inventopos/presentation/transactions/widgets/complete_transaction_bill_card.dart';
import 'package:inventopos/presentation/transactions/widgets/transaction_bill_actions_feedback_listener.dart';

class CompleteTransactionsScreen extends StatefulWidget {
  const CompleteTransactionsScreen({super.key});

  @override
  State<CompleteTransactionsScreen> createState() =>
      _CompleteTransactionsScreenState();
}

class _CompleteTransactionsScreenState
    extends State<CompleteTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showDateRangePicker(BuildContext blocContext) async {
    final cubit = blocContext.read<CompleteTransactionsBloc>();
    final lastSelectable = DateTime.now();
    final firstSelectable = DateTime(2000);

    DateTimeRange? initialRange;
    final s = cubit.state.startDate;
    final e = cubit.state.endDate;
    if (s != null) {
      final start = DatePickerUtils.clampInitial(
        preferred: s,
        fallback: lastSelectable,
        first: firstSelectable,
        last: lastSelectable,
      );
      final endRaw = e ?? s;
      final end = DatePickerUtils.clampInitial(
        preferred: endRaw,
        fallback: start,
        first: start,
        last: lastSelectable,
      );
      final endAdj = end.isBefore(start) ? start : end;
      initialRange = DateTimeRange(start: start, end: endAdj);
    }

    final result = await showDateRangePicker(
      context: blocContext,
      firstDate: firstSelectable,
      lastDate: lastSelectable,
      initialDateRange: initialRange,
      helpText: 'Select date range',
    );

    if (result != null) {
      cubit.setDateRange(result.start, result.end);
    }
  }

  Future<void> _deleteTransaction(String docId) async {
    final session = context.read<AuthRepository>().currentSession;
    if (session == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    if (!mounted) return;
    context.read<TransactionBillActionsBloc>().add(
          TransactionBillDeleteRequested(docId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              CompleteTransactionsBloc(context.read<ObserveBillsUseCase>()),
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
            child: BlocBuilder<CompleteTransactionsBloc,
                CompleteTransactionsViewState>(
              builder: (context, txState) {
                return Scaffold(
                  appBar: AppBar(
                    title: txState.isSearching
                        ? TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search by Customer Name',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) => blocContext
                                .read<CompleteTransactionsBloc>()
                                .setSearchQuery(value),
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Completed Transactions',
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
                              .read<CompleteTransactionsBloc>()
                              .toggleSearchMode();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_alt),
                        onPressed: () => _showDateRangePicker(blocContext),
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final session =
                                context.read<AuthRepository>().currentSession;
                            if (session == null) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                        'Please login to view transactions'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.go('/login');
                                      },
                                      child: const Text('Go to Login'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (txState.bills.isEmpty) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final completeRows = txState.bills
                                .where((b) => b.paymentStatus == 'complete')
                                .toList();

                            if (completeRows.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No completed transactions',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final filteredRows = completeRows.where((bill) {
                              final customerName = bill.customerName;
                              final createdAt = bill.createdAt;

                              final matchesSearchQuery = customerName
                                  .toLowerCase()
                                  .contains(txState.searchQuery.toLowerCase());

                              final isWithinDateRange = (txState.startDate ==
                                          null ||
                                      createdAt.isAfter(txState.startDate!)) &&
                                  (txState.endDate == null ||
                                      createdAt.isBefore(txState.endDate!
                                          .add(const Duration(days: 1))));

                              return matchesSearchQuery && isWithinDateRange;
                            }).toList();

                            final Map<String, List<Bill>> groupedTransactions =
                                {};
                            for (final bill in filteredRows) {
                              final date = DateFormat('yyyy-MM-dd')
                                  .format(bill.createdAt);
                              groupedTransactions.putIfAbsent(date, () => []);
                              groupedTransactions[date]!.add(bill);
                            }

                            return ListView.builder(
                              itemCount: groupedTransactions.length,
                              itemBuilder: (context, index) {
                                final date =
                                    groupedTransactions.keys.elementAt(index);
                                final transactions = groupedTransactions[date]!;

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
                                    ...transactions.map((bill) {
                                      return CompleteTransactionBillCard(
                                        bill: bill,
                                        onShowBill: () =>
                                            openBillPdfForBill(context, bill),
                                        onDelete: () =>
                                            _deleteTransaction(bill.id),
                                      );
                                    }),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
