import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/core/utils/date_picker_utils.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/presentation/transactions/cubit/incomplete_transactions_cubit.dart';
import 'package:inventopos/presentation/transactions/cubit/incomplete_transactions_state.dart';
import 'package:inventopos/supabase_mappers.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncompleteTransactionsScreen extends StatefulWidget {
  const IncompleteTransactionsScreen({super.key});

  @override
  _IncompleteTransactionsScreenState createState() =>
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
    return BlocProvider(
      create: (_) =>
          IncompleteTransactionsCubit(context.read<BillsRepository>()),
      child: Builder(
        builder: (blocContext) {
          return BlocBuilder<IncompleteTransactionsCubit,
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
                      icon: Icon(txState.isSearching ? Icons.close : Icons.search),
                      onPressed: () {
                        if (txState.isSearching) {
                          _searchController.clear();
                        }
                        blocContext
                            .read<IncompleteTransactionsCubit>()
                            .toggleSearchMode();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final lastSelectable = DateTime.now();
                        final firstSelectable = DateTime(2000);
                        DateTime? pickedDate = await showDatePicker(
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
                          blocContext
                              .read<IncompleteTransactionsCubit>()
                              .setSelectedDate(pickedDate);
                        }
                      },
                    ),
                  ],
                ),
                body: Builder(
                  builder: (bodyContext) {
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
                                bodyContext.go('/login');
                              },
                              child: const Text('Go to Login'),
                            ),
                          ],
                        ),
                      );
                    }

                    _checkForOverdueTransactions(user.id);

                    if (txState.rawBillRows.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final partialRows = txState.rawBillRows
                        .where((r) => r['payment_status'] == 'partial')
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

                    final filteredBills = partialRows.where((row) {
                      final data = SupabaseMappers.billFromRow(row);
                      final customerName = data['customerName'] as String;
                      return customerName
                          .toLowerCase()
                          .contains(txState.searchQuery);
                    }).toList();

                    final dateFilteredBills = txState.selectedDate != null
                        ? filteredBills.where((row) {
                            final data = SupabaseMappers.billFromRow(row);
                            final createdAt = data['createdAt'] as DateTime;
                            return DateFormat('yyyy-MM-dd').format(createdAt) ==
                                DateFormat('yyyy-MM-dd')
                                    .format(txState.selectedDate!);
                          }).toList()
                        : filteredBills;

                    final Map<String, List<Map<String, dynamic>>> groupedBills =
                        {};
                    for (final row in dateFilteredBills) {
                      final data = SupabaseMappers.billFromRow(row);
                      final date = DateFormat('yyyy-MM-dd')
                          .format(data['createdAt'] as DateTime);
                      groupedBills.putIfAbsent(date, () => []);
                      groupedBills[date]!.add(row);
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
                            ...bills.map((row) {
                              final data = SupabaseMappers.billFromRow(row);
                              final id = row['id'] as String;
                              return _buildBillCard(context, id, data);
                            }).toList(),
                          ],
                        );
                      },
                    );
                  },
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

  Future<void> _showSignedBill(String billUrl) async {
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

// Check for overdue transactions and create notifications
  void _checkForOverdueTransactions(String userId) async {
    final now = DateTime.now();
    final tenDaysAgo = now.subtract(Duration(days: 5));

    final supabase = Supabase.instance.client;
    final rows = await supabase
        .from('bills')
        .select()
        .eq('user_id', userId)
        .eq('payment_status', 'partial');

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final data = SupabaseMappers.billFromRow(row);
      final createdAt = data['createdAt'] as DateTime;

      if (createdAt.isBefore(tenDaysAgo)) {
        await supabase.from('notifications').insert({
          'user_id': userId,
          'message':
              'You have a payment due for ${data['customerName']}.',
          'is_read': false,
        });
      }
    }
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
            .read<IncompleteTransactionsCubit>()
            .setSearchQuery(value.toLowerCase());
      },
    );
  }

  Future<void> _updatePayment(
    String billId,
    double additionalAmount,
    Map<String, dynamic> billData,
  ) async {
    final currentPaidAmount = (billData['paidAmount'] as num).toDouble();
    final totalAmount = (billData['totalAmount'] as num).toDouble();
    final newPaidAmount = currentPaidAmount + additionalAmount;

    await Supabase.instance.client.from('bills').update({
      'paid_amount': newPaidAmount,
      'payment_status': newPaidAmount >= totalAmount ? 'complete' : 'partial',
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', billId);
  }

  Future<void> _showUpdatePaymentDialog(
    BuildContext context,
    String billId,
    double remainingAmount,
    Map<String, dynamic> billData,
  ) async {
    final TextEditingController amountController = TextEditingController();
    bool updateSignedBill = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              remainingAmount <= 0 ? 'Update Final Payment' : 'Update Payment'),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0 || amount > remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }

                await _updatePayment(billId, amount, billData);

                if (amount == remainingAmount && updateSignedBill) {
                  await _updateSignedBill(billId);
                }

                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBillCard(
      BuildContext context, String billId, Map<String, dynamic> billData) {
    final totalAmount = (billData['totalAmount'] as num).toDouble();
    final paidAmount = (billData['paidAmount'] as num).toDouble();
    final remainingAmount = totalAmount - paidAmount;
    final signedBillUrl = billData['signedBillUrl'] as String?;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text(billData['customerName']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone: ${billData['customerPhone'] ?? 'N/A'}'),
                _buildAmountRow('Total Amount:', totalAmount),
                _buildAmountRow('Amount Paid:', paidAmount),
                _buildAmountRow('Remaining Amount:', remainingAmount),
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
                  onPressed: signedBillUrl != null
                      ? () => _showSignedBill(signedBillUrl)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: remainingAmount > 0
                      ? () => _showUpdatePaymentDialog(
                          context, billId, remainingAmount, billData)
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





























































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// class IncompleteTransactionsScreen extends StatefulWidget {
//   const IncompleteTransactionsScreen({Key? key}) : super(key: key);

//   @override
//   _IncompleteTransactionsScreenState createState() =>
//       _IncompleteTransactionsScreenState();
// }

// class _IncompleteTransactionsScreenState extends State<IncompleteTransactionsScreen> {
//   // ... (keep existing variables) ...

//   Future<void> _updateSignedBill(String billId) async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.camera);

//     if (image != null) {
//       try {
//         // Show loading dialog
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (BuildContext context) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           },
//         );

//         // Delete previous signed bill if exists
//         final previousBillRef = await FirebaseFirestore.instance
//             .collection('bills')
//             .doc(billId)
//             .get();
        
//         if (previousBillRef.data()?['signedBillUrl'] != null) {
//           await FirebaseStorage.instance
//               .refFromURL(previousBillRef.data()!['signedBillUrl'])
//               .delete();
//         }

//         // Upload new image
//         final storageRef = FirebaseStorage.instance
//             .ref()
//             .child('signed_bills')
//             .child('$billId.jpg');
        
//         await storageRef.putFile(File(image.path));
//         final downloadUrl = await storageRef.getDownloadURL();

//         // Update Firestore
//         await FirebaseFirestore.instance
//             .collection('bills')
//             .doc(billId)
//             .update({
//           'signedBillUrl': downloadUrl,
//           'lastSignedBillUpdate': FieldValue.serverTimestamp(),
//         });

//         Navigator.pop(context); // Dismiss loading dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Signed bill updated successfully')),
//         );
//       } catch (e) {
//         Navigator.pop(context); // Dismiss loading dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error updating signed bill: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _showSignedBill(String billUrl) async {
//     await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Container(
//             width: MediaQuery.of(context).size.width * 0.9,
//             height: MediaQuery.of(context).size.height * 0.7,
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//                 Expanded(
//                   child: Image.network(
//                     billUrl,
//                     fit: BoxFit.contain,
//                     loadingBuilder: (context, child, loadingProgress) {
//                       if (loadingProgress == null) return child;
//                       return const Center(child: CircularProgressIndicator());
//                     },
//                     errorBuilder: (context, error, stackTrace) {
//                       return const Center(
//                         child: Text('Error loading image'),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _showUpdatePaymentDialog(
//     BuildContext context,
//     String billId,
//     double remainingAmount,
//     Map<String, dynamic> billData,
//   ) async {
//     final TextEditingController amountController = TextEditingController();
//     bool updateSignedBill = false;

//     return showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: Text(remainingAmount <= 0 ? 'Update Final Payment' : 'Update Payment'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Remaining Amount: ₹${remainingAmount.toStringAsFixed(2)}'),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: amountController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: 'Amount Paid',
//                   border: OutlineInputBorder(),
//                   prefixText: '₹',
//                 ),
//               ),
//               if (double.tryParse(amountController.text) == remainingAmount)
//                 CheckboxListTile(
//                   title: const Text('Update signed bill'),
//                   value: updateSignedBill,
//                   onChanged: (bool? value) {
//                     setState(() {
//                       updateSignedBill = value ?? false;
//                     });
//                   },
//                 ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 final amount = double.tryParse(amountController.text);
//                 if (amount == null || amount <= 0 || amount > remainingAmount) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Please enter a valid amount'),
//                     ),
//                   );
//                   return;
//                 }

//                 await _updatePayment(billId, amount, billData);
                
//                 if (amount == remainingAmount && updateSignedBill) {
//                   await _updateSignedBill(billId);
//                 }
                
//                 Navigator.pop(context);
//               },
//               child: const Text('Update'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBillCard(
//       BuildContext context, String billId, Map<String, dynamic> billData) {
//     final totalAmount = (billData['totalAmount'] as num).toDouble();
//     final paidAmount = (billData['paidAmount'] as num).toDouble();
//     final remainingAmount = totalAmount - paidAmount;
//     final signedBillUrl = billData['signedBillUrl'] as String?;

//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       child: Column(
//         children: [
//           ListTile(
//             title: Text(billData['customerName']),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Phone: ${billData['customerPhone'] ?? 'N/A'}'),
//                 _buildAmountRow('Total Amount:', totalAmount),
//                 _buildAmountRow('Amount Paid:', paidAmount),
//                 _buildAmountRow('Remaining Amount:', remainingAmount),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.upload_file),
//                   label: const Text('Update Signed Bill'),
//                   onPressed: () => _updateSignedBill(billId),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.receipt_long),
//                   label: const Text('Show Bill'),
//                   onPressed: signedBillUrl != null
//                       ? () => _showSignedBill(signedBillUrl)
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: remainingAmount > 0
//                       ? () => _showUpdatePaymentDialog(
//                           context, billId, remainingAmount, billData)
//                       : null,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
