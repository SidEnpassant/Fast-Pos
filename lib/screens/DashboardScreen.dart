// home_dashboard_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/Account/myAccount.dart';
import 'package:inventopos/bottom%20navigation%20bar/bottomNavbar.dart';
import 'package:inventopos/Notification/notificationsScreen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String businessName = 'Your Business';
  @override
  void initState() {
    super.initState();
    _loadBusinessName();
  }

  Future<void> _loadBusinessName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      businessName = prefs.getString('businessName') ?? 'Your Business';
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatisticsCards(),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => Navigator.pushNamed(context, '/create-bill'),
      //   label: const Text('New Bill'),
      //   icon: const Icon(Icons.add),
      //   backgroundColor: Colors.white,
      // ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.store, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Loading...');
                }
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data?['businessName'] ?? 'Your Business',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login', // Adjust this to your actual login route
                (route) => false,
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    print("Current User ID: $userId");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        double totalRevenue = 0;
        int completedTransactions = 0;
        int pendingTransactions = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Debugging: Log the fetched bill documents
          print("Bill Doc: ${data}");
          print(
              "Total Amount: ${data['totalAmount']}, Payment Status: ${data['paymentStatus']}, Paid Amount: ${data['paidAmount']}");

          // Determine revenue based on payment status
          if (data['paymentStatus'] == 'complete') {
            totalRevenue += (data['totalAmount'] ?? 0).toDouble();
            completedTransactions++;
          } else if (data['paymentStatus'] == 'partial') {
            totalRevenue += (data['paidAmount'] ?? 0).toDouble();
            pendingTransactions++;
          } else {
            // Handle other payment statuses if needed
            pendingTransactions++;
          }
        }

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
                'Total Revenue',
                '₹${totalRevenue.toStringAsFixed(2)}',
                Icons.currency_rupee,
                Colors.green),
            _buildStatCard(
                'Total Transactions',
                '${snapshot.data!.docs.length}',
                Icons.receipt_long,
                Colors.blue),
            _buildStatCard('Completed', '$completedTransactions',
                Icons.check_circle_outline, Colors.purple),
            _buildStatCard('Pending', '$pendingTransactions',
                Icons.pending_actions, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Complete\nTransactions',
                Icons.check_circle_outline,
                Colors.green,
                () => Navigator.pushNamed(context, '/complete-transactions'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                'Incomplete\nTransactions',
                Icons.pending_actions,
                Colors.orange,
                () => Navigator.pushNamed(context, '/incomplete-transactions'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // If no user is logged in, show appropriate message
    if (userId == null) {
      return const Center(
        child: Text(
          'Please log in to view recent bills',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Bills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bills')
              .where('userId',
                  isEqualTo: userId) // Changed from businessId to userId
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            // Handle permission error specifically
            if (snapshot.hasError) {
              print("Snapshot Error: ${snapshot.error}");
              if (snapshot.error.toString().contains('permission')) {
                return const Center(
                  child: Text(
                    "You don't have permission to view bills. Please contact support.",
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Center(
                child: Text(
                  "Error loading bills: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No bills found",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                if (!_isValidBillData(data)) {
                  return const SizedBox.shrink();
                }
                return _buildTransactionItem(data);
              },
            );
          },
        ),
      ],
    );
  }

  // Helper method to validate bill data structure
  bool _isValidBillData(Map<String, dynamic> data) {
    return data.containsKey('customerName') &&
        data.containsKey('totalAmount') &&
        data.containsKey('paidAmount') &&
        data.containsKey('paymentStatus');
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    final customerName = data['customerName'] ?? 'Unknown Customer';
    final totalAmount = data['totalAmount']?.toString() ?? '0.00';
    final paidAmount = data['paidAmount']?.toString() ?? '0.00';
    final paymentStatus = data['paymentStatus'] ?? 'Unknown';

    Color statusColor = Colors.grey;
    if (paymentStatus.toLowerCase() == 'paid') {
      statusColor = Colors.green;
    } else if (paymentStatus.toLowerCase() == 'partial') {
      statusColor = Colors.orange;
    } else if (paymentStatus.toLowerCase() == 'unpaid') {
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Total: ₹$totalAmount',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Paid: ₹$paidAmount',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paymentStatus,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
