import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getCompleteTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    // Get current user ID
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No authenticated user found');
    }

    // Start with base query
    Query query = _firestore
        .collection('transactions')
        .where('businessId', isEqualTo: userId);

    // Add multiple status conditions using 'where in' to check for both COMPLETE and PAID
    query = query.where('status', whereIn: [
      'COMPLETE',
      'PAID',
      'complete',
      'paid',
      'Full Paid',
      'FULL_PAID'
    ]);

    // Add date range if provided
    if (startDate != null && endDate != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          isLessThanOrEqualTo:
              Timestamp.fromDate(endDate.add(const Duration(days: 1))));
    }

    // Order by creation date
    query = query.orderBy('createdAt', descending: true);

    // Add search query if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      query = query
          .where('customerNameLower', isGreaterThanOrEqualTo: searchLower)
          .where('customerNameLower',
              isLessThanOrEqualTo: searchLower + '\uf8ff');
    }

    return query.snapshots();
  }

  // Helper method to check transactions directly
  Future<void> debugCheckTransactions() async {
    try {
      final userId = _auth.currentUser?.uid;
      print('Checking transactions for user: $userId');

      final QuerySnapshot completeSnapshot = await _firestore
          .collection('transactions')
          .where('businessId', isEqualTo: userId)
          .get();

      print('Total transactions found: ${completeSnapshot.docs.length}');

      for (var doc in completeSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Transaction ID: ${doc.id}');
        print('Status: ${data['status']}');
        print('Payment Status: ${data['paymentStatus']}');
        print('Created At: ${data['createdAt']}');
        print('-------------------');
      }
    } catch (e) {
      print('Debug Error: $e');
    }
  }
}
