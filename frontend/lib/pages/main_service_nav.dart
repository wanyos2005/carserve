import 'package:flutter/material.dart';
import 'package:car_platform/pages/booking_page.dart';
import 'package:car_platform/pages/service_log_page.dart';

class MainServiceNav extends StatefulWidget {
  const MainServiceNav({super.key});

  @override
  State<MainServiceNav> createState() => _MainServiceNavState();
}

class _MainServiceNavState extends State<MainServiceNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    BookingPage(),
    ServiceLogPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Book Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Service Logs',
          ),
        ],
      ),
    );
  }
}
