import 'package:flutter/material.dart';
import 'package:driveon_car_platform/pages/enhanced_booking_page.dart';
import 'package:driveon_car_platform/pages/service_log_page.dart';

class MainServiceNav extends StatefulWidget {
  const MainServiceNav({super.key});

  @override
  State<MainServiceNav> createState() => _MainServiceNavState();
}

class _MainServiceNavState extends State<MainServiceNav> {
  int _selectedIndex = 1;

  final List<Widget> _pages = const [
    EnhancedBookingPage(),
    ServiceLogPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red[600],
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month, size: 28),
            activeIcon: Icon(Icons.calendar_month, size: 32),
            label: 'Book Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 28),
            activeIcon: Icon(Icons.history, size: 32),
            label: 'Service Logs',
          ),
        ],
      ),
    );
  }
}
