import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_date_section_header.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
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
    final bloc = blocContext.read<CompleteTransactionsBloc>();
    final lastSelectable = DateTime.now();
    final firstSelectable = DateTime(2000);

    DateTimeRange? initialRange;
    final s = bloc.state.startDate;
    final e = bloc.state.endDate;
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
      bloc.setDateRange(result.start, result.end);
    }
  }

  Future<void> _deleteTransaction(String docId) async {
    final session = context.read<AuthRepository>().currentSession;
    if (session == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>  Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: AppShimmer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                return AppScreenScaffold(
                  title: txState.isSearching ? null : 'Completed Transactions',
                  titleWidget: txState.isSearching
                      ? TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by customer name',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) => blocContext
                              .read<CompleteTransactionsBloc>()
                              .setSearchQuery(value),
                        )
                      : null,
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
                            .read<CompleteTransactionsBloc>()
                            .toggleSearchMode();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_alt_outlined),
                      onPressed: () => _showDateRangePicker(blocContext),
                    ),
                  ],
                  body: Builder(
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

                            if (txState.loading) {
                              return const AppSkeletonList(itemCount: 8);
                            }

                            final groupedTransactions = txState.groupedTransactions;

                            if (groupedTransactions.isEmpty) {
                              return const AppEmptyState(
                                icon: Icons.check_circle_outline,
                                title: 'No completed transactions',
                                message:
                                    'Completed bills will appear here after full payment.',
                              );
                            }

                            final dates = groupedTransactions.keys.toList();

                            return ListView.builder(
                              itemCount: dates.length,
                              itemBuilder: (context, index) {
                                final date = dates[index];
                                final transactions = groupedTransactions[date]!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppDateSectionHeader(
                                      label: DateFormat('MMMM dd, yyyy')
                                          .format(DateTime.parse(date)),
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
