import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            : const Text('Completed Transactions'),
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
                              return _buildTransactionCard(context, data);
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
      BuildContext context, Map<String, dynamic> data) {
    final totalAmount = (data['totalAmount'] as num).toDouble();
    final customerName = data['customerName'] as String;
    final customerPhone = data['customerPhone'] as String;
    final paymentMethod = data['paymentMethod'] as String? ?? 'Cash';
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

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
                              '${item['name']} x ${item['quantity']}',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
