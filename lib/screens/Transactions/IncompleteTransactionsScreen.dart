import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class IncompleteTransactionsScreen extends StatefulWidget {
  const IncompleteTransactionsScreen({Key? key}) : super(key: key);

  @override
  _IncompleteTransactionsScreenState createState() =>
      _IncompleteTransactionsScreenState();
}

class _IncompleteTransactionsScreenState
    extends State<IncompleteTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;
  DateTime? selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? _buildSearchField()
            : Text(
                'Pending Transactions',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!authSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Please login to view transactions'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            );
          }

          final userId = authSnapshot.data!.uid;
          return _buildBody(userId);
        },
      ),
    );
  }

  Widget _buildBody(String userId) {
    // Check for overdue transactions and create notifications
    _checkForOverdueTransactions(userId);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'partial')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey[400]),
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

        // Filter bills based on search query
        final filteredBills = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final customerName = data['customerName'] as String;
          return customerName.toLowerCase().contains(searchQuery);
        }).toList();

        // Further filter bills by selected date
        final dateFilteredBills = selectedDate != null
            ? filteredBills.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final createdAt = (data['createdAt'] as Timestamp).toDate();
                return DateFormat('yyyy-MM-dd').format(createdAt) ==
                    DateFormat('yyyy-MM-dd').format(selectedDate!);
              }).toList()
            : filteredBills;

        // Group bills by date
        Map<String, List<DocumentSnapshot>> groupedBills = {};
        for (var doc in dateFilteredBills) {
          final data = doc.data() as Map<String, dynamic>;
          final date = DateFormat('yyyy-MM-dd')
              .format((data['createdAt'] as Timestamp).toDate());
          groupedBills.putIfAbsent(date, () => []);
          groupedBills[date]!.add(doc);
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
                    DateFormat('MMMM dd, yyyy').format(DateTime.parse(date)),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...bills.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildBillCard(context, doc.id, data);
                }).toList(),
              ],
            );
          },
        );
      },
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

        // Delete previous signed bill if exists
        final previousBillRef = await FirebaseFirestore.instance
            .collection('bills')
            .doc(billId)
            .get();

        if (previousBillRef.data()?['signedBillUrl'] != null) {
          await FirebaseStorage.instance
              .refFromURL(previousBillRef.data()!['signedBillUrl'])
              .delete();
        }

        // Upload new image
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('signed_bills')
            .child('$billId.jpg');

        await storageRef.putFile(File(image.path));
        final downloadUrl = await storageRef.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('bills')
            .doc(billId)
            .update({
          'signedBillUrl': downloadUrl,
          'lastSignedBillUpdate': FieldValue.serverTimestamp(),
        });

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

    final snapshot = await FirebaseFirestore.instance
        .collection('bills')
        .where('userId', isEqualTo: userId)
        .where('paymentStatus', isEqualTo: 'partial')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp).toDate();

      if (createdAt.isBefore(tenDaysAgo)) {
        // Create a notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'message': 'You have a payment due for ${data['customerName']}.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Search by customer name...',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value.toLowerCase();
        });
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

    await FirebaseFirestore.instance.collection('bills').doc(billId).update({
      'paidAmount': newPaidAmount,
      'paymentStatus': newPaidAmount >= totalAmount ? 'complete' : 'partial',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _markAsFullyPaid(
    BuildContext context,
    String billId,
    Map<String, dynamic> billData,
  ) async {
    final totalAmount = (billData['totalAmount'] as num).toDouble();

    await FirebaseFirestore.instance.collection('bills').doc(billId).update({
      'paidAmount': totalAmount,
      'paymentStatus': 'complete',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
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
