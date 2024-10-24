import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:inventopos/screens/Account/myAccount.dart';
import 'package:inventopos/screens/Dashboard/MonthlyRevenueAnalysis.dart';
import 'package:inventopos/screens/Notification/notificationsScreen.dart';
import 'package:inventopos/screens/Bill/BillGenerationScreen.dart';
import 'package:inventopos/screens/Dashboard/DashboardScreen.dart';

class NavBarScreen extends StatefulWidget {
  const NavBarScreen({super.key});

  @override
  _NavBarScreenState createState() => _NavBarScreenState();
}

class _NavBarScreenState extends State<NavBarScreen> {
  int _currentIndex = 0;

  // List of widgets representing each tab
  final List<Widget> _pages = [
    DashboardScreen(), // Your dashboard screen
    MonthlyRevenueAnalysis(), //Analysis Screen
    BillGenerationScreen(), // Your bill generation screen
    NotificationsScreen(), // Your notification screen
    MyAccountPage(), // Your profile screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        height: 65, // Set a fixed height for the bottom nav bar
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Set background color
          borderRadius: BorderRadius.circular(
              30), // Rounded corners for the bottom nav bar
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 138, 168, 245).withOpacity(0.1),
              spreadRadius: 10,
              blurRadius: 10,
              offset: Offset(3, 0), // Position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
              30), // Make sure corners are rounded for the BottomNavyBar
          child: BottomNavyBar(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            selectedIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavyBarItem(
                icon: Icon(Icons.dashboard_customize_outlined),
                title: Text('Dashboard'),
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.grey,
              ),
              BottomNavyBarItem(
                icon: Icon(Icons.analytics_outlined),
                title: Text('Analysis'),
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.grey,
              ),
              BottomNavyBarItem(
                icon: Icon(Icons.receipt_outlined),
                title: Text('New Bill'),
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.grey,
              ),
              BottomNavyBarItem(
                icon: Icon(Icons.notifications_none_outlined),
                title: Text('Notifications'),
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.grey,
              ),
              BottomNavyBarItem(
                icon: Icon(Icons.person_2_outlined),
                title: Text('Profile'),
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
