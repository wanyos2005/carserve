import 'package:flutter/material.dart';
import 'package:driveon_car_platform/pages/driveon_alerts_page.dart';
import 'package:driveon_car_platform/pages/enhanced_booking_page.dart';
import 'package:driveon_car_platform/pages/service_log_page.dart';
import 'package:driveon_car_platform/pages/vehicle_list_page.dart';
import 'package:driveon_car_platform/pages/services_providers_page.dart';
import 'package:driveon_car_platform/pages/history_page.dart';
import 'package:driveon_car_platform/pages/user_loyalty_page.dart';
import 'package:driveon_car_platform/components/notifications_settings_sheet.dart';
import 'package:driveon_car_platform/services/alerts_service.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';

class MainServiceNav extends StatefulWidget {
  const MainServiceNav({super.key});

  @override
  State<MainServiceNav> createState() => _MainServiceNavState();
}

class _MainServiceNavState extends State<MainServiceNav> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isPrivilegesExpanded = false;
  int _unreadAlertCount = 0;
  List<Alert> _recentAlerts = [];

  final List<Widget> _pages = const [
    DrivonAlertsPage(),
    EnhancedBookingPage(),
    ServiceLogPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _togglePrivileges() {
    setState(() => _isPrivilegesExpanded = !_isPrivilegesExpanded);
  }

  Future<void> _loadNotifications() async {
    try {
      final userIdStr = UserContextService.currentContext?.id;
      if (userIdStr == null) return;
      final userId = int.tryParse(userIdStr);
      if (userId == null) return;
      final count = await AlertsService.getUnreadCount();
      final alerts = await AlertsService.getAlerts(userId: userId, limit: 5);
      if (mounted) setState(() { _unreadAlertCount = count; _recentAlerts = alerts; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Full-screen content ──────────────────────────────────────
            if (_isPrivilegesExpanded)
              Positioned.fill(
                top: 52,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildPrivilegeItem('My Vehicles', Icons.directions_car,
                            Colors.blue, () {
                          _togglePrivileges();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const VehicleListPage()));
                        }),
                        _buildPrivilegeItem('Insurance', Icons.shield,
                            Colors.orange, () {
                          _togglePrivileges();
                          Navigator.pushNamed(context, '/insurance/dashboard');
                        }),
                        _buildPrivilegeItem('Expenses',
                            Icons.account_balance_wallet, Colors.purple, () {
                          _togglePrivileges();
                          Navigator.pushNamed(context, '/expenses');
                        }),
                        _buildPrivilegeItem(
                            'Top Providers', Icons.star_rate, Colors.amber, () {
                          _togglePrivileges();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ServicesProvidersPage()));
                        }),
                        _buildPrivilegeItem(
                          _unreadAlertCount > 0
                              ? 'Alerts ($_unreadAlertCount unread)'
                              : 'Alerts',
                          Icons.notifications,
                          Colors.red,
                          () {
                            _togglePrivileges();
                            Navigator.pushNamed(context, '/alerts');
                          },
                        ),
                        _buildPrivilegeItem('History', Icons.history,
                            Colors.indigo, () {
                          _togglePrivileges();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HistoryPage()));
                        }),
                        _buildPrivilegeItem(
                            'Loyalty Program', Icons.stars, Colors.amber, () {
                          _togglePrivileges();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UserLoyaltyPage()));
                        }),
                        _buildPrivilegeItem(
                            'Profile & Settings', Icons.settings, Colors.teal,
                            () {
                          _togglePrivileges();
                          showNotificationsSettingsSheet(
                            context: context,
                            unreadAlertCount: _unreadAlertCount,
                            recentAlerts: _recentAlerts,
                            onRefreshNotifications: _loadNotifications,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(child: _pages[_selectedIndex]),

            // ── Floating menu button (overlaid, zero layout cost) ────────
            Positioned(
              top: 8,
              right: 16,
              child: GestureDetector(
                onTap: _togglePrivileges,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedRotation(
                        turns: _isPrivilegesExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(Icons.menu,
                            color: theme.iconTheme.color, size: 22),
                      ),
                      if (_unreadAlertCount > 0 && !_isPrivilegesExpanded)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              _unreadAlertCount > 9 ? '9+' : '$_unreadAlertCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() {
          _selectedIndex = index;
          _isPrivilegesExpanded = false;
        }),
        selectedItemColor: Colors.red[600],
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined, size: 28),
            activeIcon: Icon(Icons.campaign, size: 32),
            label: 'DriveOn Alerts',
          ),
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

  Widget _buildPrivilegeItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: theme.iconTheme.color?.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
