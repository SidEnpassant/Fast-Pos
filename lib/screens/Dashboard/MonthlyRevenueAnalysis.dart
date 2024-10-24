import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyRevenueAnalysis extends StatefulWidget {
  const MonthlyRevenueAnalysis({Key? key}) : super(key: key);

  @override
  State<MonthlyRevenueAnalysis> createState() => _MonthlyRevenueAnalysisState();
}

class _MonthlyRevenueAnalysisState extends State<MonthlyRevenueAnalysis> {
  String? selectedMonth;
  bool showChart = true;

  @override
  void initState() {
    super.initState();
    // Initialize selectedMonth in initState
    selectedMonth = DateFormat('MMM yyyy').format(DateTime.now());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.analytics_outlined),
          const SizedBox(width: 8),
          Text(
            'Revenue Analysis',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: 116,
          ),
          IconButton(
            icon: Icon(
              showChart ? Icons.table_chart : Icons.show_chart,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => setState(() => showChart = !showChart),
          ),
        ],
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      iconTheme: IconThemeData(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      titleTextStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenueSection() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return _buildErrorWidget('User not authenticated');
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bills')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget('Error loading data: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return _buildShimmerLoading();
          }

          // Process data to get monthly revenues
          Map<String, double> monthlyRevenues = {};
          Map<String, int> monthlyTransactions = {};

          for (var doc in snapshot.data!.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;

              DateTime timestamp;
              if (data['createdAt'] is Timestamp) {
                timestamp = (data['createdAt'] as Timestamp).toDate();
              } else {
                continue;
              }

              final monthYear = DateFormat('MMM yyyy').format(timestamp);

              double amount = 0;
              if (data['paymentStatus'] == 'complete') {
                amount = (data['totalAmount'] ?? 0).toDouble();
              } else if (data['paymentStatus'] == 'partial') {
                amount = (data['paidAmount'] ?? 0).toDouble();
              }

              monthlyRevenues.update(
                monthYear,
                (value) => value + amount,
                ifAbsent: () => amount,
              );

              monthlyTransactions.update(
                monthYear,
                (value) => value + 1,
                ifAbsent: () => 1,
              );
            } catch (e) {
              debugPrint('Error processing document: $e');
              continue;
            }
          }

          if (monthlyRevenues.isEmpty) {
            return _buildErrorWidget('No transaction data available');
          }

          final sortedMonths = monthlyRevenues.keys.toList()
            ..sort((a, b) => DateFormat('MMM yyyy')
                .parse(b)
                .compareTo(DateFormat('MMM yyyy').parse(a)));

          if (selectedMonth == null || !sortedMonths.contains(selectedMonth)) {
            selectedMonth = sortedMonths.first;
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // View Toggle
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                        ),
                      ),

                      // Month Filter
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedMonth,
                              isExpanded: true,
                              items: sortedMonths.map((String month) {
                                return DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(
                                    month,
                                    style: GoogleFonts.poppins(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => selectedMonth = newValue);
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      // Stats Cards
                      if (selectedMonth != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatsCard(
                                  'Revenue',
                                  '₹${NumberFormat('#,##,###.##').format(monthlyRevenues[selectedMonth] ?? 0)}',
                                  Icons.account_balance_wallet,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatsCard(
                                  'Transactions',
                                  '${monthlyTransactions[selectedMonth] ?? 0}',
                                  Icons.receipt_long,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Chart or Table
                      if (showChart)
                        _buildRevenueChart(sortedMonths, monthlyRevenues)
                      else
                        _buildRevenueTable(
                            sortedMonths, monthlyRevenues, monthlyTransactions),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<String> months, Map<String, double> revenues) {
    try {
      // Take only the last 6 months
      final recentMonths = months.take(6).toList().reversed.toList();
      final revenueData = recentMonths.map((m) => revenues[m] ?? 0).toList();

      // Find max revenue for better scaling
      final maxRevenue =
          revenueData.reduce((max, value) => value > max ? value : max);
      final yInterval = (maxRevenue / 5).roundToDouble();

      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[400]!.withOpacity(0.5),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '₹${NumberFormat.compact().format(value)}',
                      style: GoogleFonts.poppins(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < recentMonths.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          recentMonths[value.toInt()].substring(0, 3),
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  revenueData.length,
                  (index) => FlSpot(index.toDouble(), revenueData[index]),
                ),
                isCurved: true,
                color: Theme.of(context).primaryColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).primaryColor,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return _buildErrorWidget('Error displaying chart');
    }
  }

  Widget _buildRevenueTable(
    List<String> months,
    Map<String, double> revenues,
    Map<String, int> transactions,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Revenue')),
            DataColumn(label: Text('Transactions')),
          ],
          rows: List.generate(months.length, (index) {
            final month = months[index];
            final revenue = revenues[month] ?? 0;
            final transactionCount = transactions[month] ?? 0;

            return DataRow(
              cells: [
                DataCell(Text(month)),
                DataCell(
                    Text('₹${NumberFormat('#,##,###.##').format(revenue)}')),
                DataCell(Text('$transactionCount')),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMonthlyRevenueSection();
  }
}
























































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:animate_do/animate_do.dart';
// import 'package:google_fonts/google_fonts.dart';

// class MonthlyRevenueAnalysis extends StatefulWidget {
//   const MonthlyRevenueAnalysis({Key? key}) : super(key: key);

//   @override
//   State<MonthlyRevenueAnalysis> createState() => _MonthlyRevenueAnalysisState();
// }

// class _MonthlyRevenueAnalysisState extends State<MonthlyRevenueAnalysis> {
//   String? selectedMonth;
//   bool showChart = true;

//   @override
//   void initState() {
//     super.initState();
//     selectedMonth = DateFormat('MMM yyyy').format(DateTime.now());
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios),
//         onPressed: () => Navigator.of(context).pop(),
//       ),
//       title: Row(
//         children: [
//           const Icon(Icons.analytics_outlined),
//           const SizedBox(width: 8),
//           Text(
//             'Revenue Analysis',
//             style: GoogleFonts.poppins(
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//       elevation: 0,
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       iconTheme: IconThemeData(
//         color: Theme.of(context).textTheme.bodyLarge?.color,
//       ),
//       titleTextStyle: TextStyle(
//         color: Theme.of(context).textTheme.bodyLarge?.color,
//       ),
//     );
//   }

//   // ... [Keep all the existing helper methods like _buildShimmerLoading, _buildErrorWidget, etc.]

//   Widget _buildMonthlyRevenueSection() {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) {
//       return _buildErrorWidget('User not authenticated');
//     }

//     return Scaffold(
//       appBar: _buildAppBar(),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('bills')
//             .where('userId', isEqualTo: userId)
//             .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return _buildErrorWidget('Error loading data: ${snapshot.error}');
//           }

//           if (!snapshot.hasData) {
//             return _buildShimmerLoading();
//           }

//           // Process data to get monthly revenues
//           Map<String, double> monthlyRevenues = {};
//           Map<String, int> monthlyTransactions = {};
          
//           for (var doc in snapshot.data!.docs) {
//             try {
//               final data = doc.data() as Map<String, dynamic>;
              
//               DateTime timestamp;
//               if (data['createdAt'] is Timestamp) {
//                 timestamp = (data['createdAt'] as Timestamp).toDate();
//               } else {
//                 continue;
//               }
              
//               final monthYear = DateFormat('MMM yyyy').format(timestamp);
              
//               double amount = 0;
//               if (data['paymentStatus'] == 'complete') {
//                 amount = (data['totalAmount'] ?? 0).toDouble();
//               } else if (data['paymentStatus'] == 'partial') {
//                 amount = (data['paidAmount'] ?? 0).toDouble();
//               }
              
//               monthlyRevenues.update(
//                 monthYear,
//                 (value) => value + amount,
//                 ifAbsent: () => amount,
//               );
              
//               monthlyTransactions.update(
//                 monthYear,
//                 (value) => value + 1,
//                 ifAbsent: () => 1,
//               );
//             } catch (e) {
//               debugPrint('Error processing document: $e');
//               continue;
//             }
//           }

//           if (monthlyRevenues.isEmpty) {
//             return _buildErrorWidget('No transaction data available');
//           }

//           final sortedMonths = monthlyRevenues.keys.toList()
//             ..sort((a, b) => DateFormat('MMM yyyy')
//                 .parse(b)
//                 .compareTo(DateFormat('MMM yyyy').parse(a)));

//           if (selectedMonth == null || !sortedMonths.contains(selectedMonth)) {
//             selectedMonth = sortedMonths.first;
//           }

//           return LayoutBuilder(
//             builder: (context, constraints) {
//               return SingleChildScrollView(
//                 child: Container(
//                   constraints: BoxConstraints(
//                     minHeight: constraints.maxHeight,
//                     maxWidth: constraints.maxWidth,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // View Toggle
//                       Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Align(
//                           alignment: Alignment.centerRight,
//                           child: IconButton(
//                             icon: Icon(
//                               showChart ? Icons.table_chart : Icons.show_chart,
//                               color: Theme.of(context).primaryColor,
//                             ),
//                             onPressed: () => setState(() => showChart = !showChart),
//                           ),
//                         ),
//                       ),

//                       // Month Filter
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: Colors.grey[300]!),
//                           ),
//                           child: DropdownButtonHideUnderline(
//                             child: DropdownButton<String>(
//                               value: selectedMonth,
//                               isExpanded: true,
//                               items: sortedMonths.map((String month) {
//                                 return DropdownMenuItem<String>(
//                                   value: month,
//                                   child: Text(
//                                     month,
//                                     style: GoogleFonts.poppins(),
//                                   ),
//                                 );
//                               }).toList(),
//                               onChanged: (String? newValue) {
//                                 if (newValue != null) {
//                                   setState(() => selectedMonth = newValue);
//                                 }
//                               },
//                             ),
//                           ),
//                         ),
//                       ),

//                       // Stats Cards
//                       if (selectedMonth != null) ...[
//                         Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: _buildStatsCard(
//                                   'Revenue',
//                                   '₹${NumberFormat('#,##,###.##').format(monthlyRevenues[selectedMonth] ?? 0)}',
//                                   Icons.account_balance_wallet,
//                                   Colors.blue,
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               Expanded(
//                                 child: _buildStatsCard(
//                                   'Transactions',
//                                   '${monthlyTransactions[selectedMonth] ?? 0}',
//                                   Icons.receipt_long,
//                                   Colors.green,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],

//                       // Chart or Table
//                       if (showChart)
//                         _buildRevenueChart(sortedMonths, monthlyRevenues)
//                       else
//                         _buildRevenueTable(sortedMonths, monthlyRevenues, monthlyTransactions),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   // ... [Keep all the existing helper methods like _buildStatsCard, _buildRevenueChart, _buildRevenueTable]

//   @override
//   Widget build(BuildContext context) {
//     return _buildMonthlyRevenueSection();
//   }
// }