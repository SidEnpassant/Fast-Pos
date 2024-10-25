import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CompleteTransactionsScreen extends StatefulWidget {
  const CompleteTransactionsScreen({Key? key}) : super(key: key);

  @override
  _CompleteTransactionsScreenState createState() =>
      _CompleteTransactionsScreenState();
}

class _CompleteTransactionsScreenState
    extends State<CompleteTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  bool isSearching = false;

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
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Customer Name',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              )
            : Text(
                'Completed Transactions',
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
                  _searchController
                      .clear(); // Clear the search input when closing
                  searchQuery = ''; // Reset the search query
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<User?>(
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
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          },
                          child: const Text('Go to Login'),
                        ),
                      ],
                    ),
                  );
                }

                final userId = authSnapshot.data!.uid;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bills')
                      .where('userId', isEqualTo: userId)
                      .where('paymentStatus', isEqualTo: 'complete')
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

                    // Filter documents based on search query and date range
                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final customerName = data['customerName'] as String;
                      final createdAt =
                          (data['createdAt'] as Timestamp).toDate();

                      // Check if the customer name matches the search query
                      final matchesSearchQuery = customerName
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());

                      // Check if the createdAt date is within the selected date range
                      final isWithinDateRange = (startDate == null ||
                              createdAt.isAfter(startDate!)) &&
                          (endDate == null ||
                              createdAt.isBefore(
                                  endDate!.add(const Duration(days: 1))));

                      return matchesSearchQuery && isWithinDateRange;
                    }).toList();

                    // Group transactions by date
                    Map<String, List<DocumentSnapshot>> groupedTransactions =
                        {};
                    for (var doc in filteredDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = DateFormat('yyyy-MM-dd')
                          .format((data['createdAt'] as Timestamp).toDate());
                      groupedTransactions.putIfAbsent(date, () => []);
                      groupedTransactions[date]!.add(doc);
                    }

                    return ListView.builder(
                      itemCount: groupedTransactions.length,
                      itemBuilder: (context, index) {
                        final date = groupedTransactions.keys.elementAt(index);
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
                            ...transactions.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id; // Get the document ID
                              return _buildTransactionCard(
                                  context, data, docId);
                            }).toList(),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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

  Future<void> _showDateRangePicker() async {
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedStartDate != null) {
      final DateTime? pickedEndDate = await showDatePicker(
        context: context,
        initialDate: endDate ?? pickedStartDate,
        firstDate: pickedStartDate,
        lastDate: DateTime.now(),
      );

      if (pickedEndDate != null) {
        setState(() {
          startDate = pickedStartDate;
          endDate = pickedEndDate;
        });
      }
    }
  }

  Widget _buildTransactionCard(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final totalAmount = (data['totalAmount'] as num).toDouble();
    final customerName = data['customerName'] as String;
    final customerPhone = data['customerPhone'] as String;
    final paymentMethod = data['paymentMethod'] as String? ?? 'Cash';
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final signedBillUrl = data['signedBillUrl'] as String?;

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
                              '${item['productName']} x ${item['quantity']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '₹${(item['totalPrice'] as num).toStringAsFixed(2)}',
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
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
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

        // First, get the document to check if it has a signed bill
        final docSnapshot = await FirebaseFirestore.instance
            .collection('bills')
            .doc(docId)
            .get();

        // If there's a signed bill URL, delete it from Storage
        if (docSnapshot.data()?['signedBillUrl'] != null) {
          final signedBillUrl = docSnapshot.data()!['signedBillUrl'] as String;
          try {
            await FirebaseStorage.instance.refFromURL(signedBillUrl).delete();
          } catch (storageError) {
            print('Error deleting signed bill: $storageError');
            // Continue with document deletion even if storage deletion fails
          }
        }

        // Delete the document from Firestore
        await FirebaseFirestore.instance
            .collection('bills')
            .doc(docId)
            .delete();

        // Dismiss loading dialog
        Navigator.pop(context);

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Transaction and associated bill deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Dismiss loading dialog if still showing
        if (context.mounted) {
          Navigator.pop(context);
        }

        // Show an error message
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
