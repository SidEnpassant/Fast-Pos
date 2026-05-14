import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/core/utils/date_picker_utils.dart';
import 'package:inventopos/application/billing/observe_bills_use_case.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/complete_transac_bloc/complete_transactions_state.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompleteTransactionsScreen extends StatefulWidget {
  const CompleteTransactionsScreen({super.key});

  @override
  _CompleteTransactionsScreenState createState() =>
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CompleteTransactionsBloc(context.read<ObserveBillsUseCase>()),
      child: Builder(
        builder: (blocContext) {
          return BlocBuilder<CompleteTransactionsBloc,
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
                  icon: Icon(txState.isSearching ? Icons.close : Icons.search),
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
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Please login to view transactions'),
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
                        return const Center(child: CircularProgressIndicator());
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

                        final isWithinDateRange =
                            (txState.startDate == null ||
                                    createdAt.isAfter(txState.startDate!)) &&
                                (txState.endDate == null ||
                                    createdAt.isBefore(txState.endDate!
                                        .add(const Duration(days: 1))));

                        return matchesSearchQuery && isWithinDateRange;
                      }).toList();

                      final Map<String, List<Bill>> groupedTransactions = {};
                      for (final bill in filteredRows) {
                        final date =
                            DateFormat('yyyy-MM-dd').format(bill.createdAt);
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
                                return _buildTransactionCard(
                                    context, bill, bill.id);
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
          );
        },
      ),
    );
  }

  Future<void> _updateSignedBill(String billId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        final supabase = Supabase.instance.client;
        try {
          await supabase.storage.from('signed_bills').remove(['$billId.jpg']);
        } catch (_) {}

        await supabase.storage.from('signed_bills').upload(
              '$billId.jpg',
              File(image.path),
              fileOptions: const FileOptions(upsert: true),
            );
        final downloadUrl =
            supabase.storage.from('signed_bills').getPublicUrl('$billId.jpg');

        await supabase.from('bills').update({
          'signed_bill_url': downloadUrl,
          'last_signed_bill_update': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', billId);

        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed bill updated successfully')),
        );
      } catch (e) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating signed bill: $e')),
        );
      }
    }
  }

  Future<void> _showSignedBill(String? billUrl) async {
    if (billUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No signed bill available')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
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
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Text('Error loading image',
                                          style:
                                              TextStyle(color: Colors.white)),
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: Image.network(
                    billUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Error loading image'),
                      );
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

  Widget _buildTransactionCard(
      BuildContext context, Bill bill, String docId) {
    final totalAmount = bill.totalAmount;
    final customerName = bill.customerName;
    final customerPhone = bill.customerPhone;
    final paymentMethod = bill.paymentMethod;
    final items = bill.lineItems;
    final signedBillUrl = bill.signedBillUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          customerName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(customerPhone),
            const SizedBox(height: 4),
            Text(
              'Amount: ₹${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Method: $paymentMethod',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                const Text('Items:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.productName} x ${item.quantity}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Update again'),
                      onPressed: () => _updateSignedBill(docId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Show Bill'),
                      onPressed: signedBillUrl != null
                          ? () => _showSignedBill(signedBillUrl)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTransaction(docId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Add this method to handle the deletion
  Future<void> _deleteTransaction(String docId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        final supabase = Supabase.instance.client;
        try {
          await supabase.storage.from('signed_bills').remove(['$docId.jpg']);
        } catch (storageError) {
          print('Error deleting signed bill: $storageError');
        }

        await supabase.from('bills').delete().eq('id', docId);

        if (context.mounted) Navigator.pop(context);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Transaction and associated bill deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
