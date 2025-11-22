import 'package:flutter/material.dart';
import 'vehicle_list_page.dart';
import 'services_providers_page.dart';
import 'history_page.dart';
import 'user_loyalty_page.dart';
import 'vehicle_form_page.dart';
import '../social_media/pages/social_hub_page.dart';
import '../components/notifications_settings_sheet.dart';
import '../services/alerts_service.dart';
import '../services/vehicle_service.dart';
import '../services/user_context_service.dart';
import '../services/fcm_service.dart';
import '../components/rating_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isPrivilegesExpanded = false;
  int _unreadAlertCount = 0;
  List<Alert> _recentAlerts = [];
  List<dynamic> _vehicles = [];
  bool _vehiclesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadVehicles();
    _setupFCMNavigation();
  }

  /// Set up FCM navigation handler to show rating dialog when rating URLs are tapped
  void _setupFCMNavigation() {
    FCMService.onNavigate = (String actionUrl) async {
      // Parse rating URL
      final ratingParams = parseRatingActionUrl(actionUrl);
      if (ratingParams != null) {
        final userIdStr = UserContextService.currentContext?.id;
        if (userIdStr != null) {
          final userId = int.tryParse(userIdStr);
          if (userId != null && mounted) {
            // Show rating dialog
            showRatingDialog(
              context: context,
              userId: userId,
              providerId: ratingParams['provider_id']!,
              bookingId: ratingParams['booking_id'],
              logId: ratingParams['log_id'],
            );
            return;
          }
        }
      }
      // For other URLs, could navigate to specific pages
      // For now, just show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action: $actionUrl')),
        );
      }
    };
  }

  @override
  void dispose() {
    // Clear the navigation handler when this widget is disposed
    FCMService.onNavigate = null;
    super.dispose();
  }

  void _togglePrivileges() {
    setState(() {
      _isPrivilegesExpanded = !_isPrivilegesExpanded;
    });
  }

  Future<void> _loadNotifications() async {
    try {
      final userIdStr = UserContextService.currentContext?.id;
      if (userIdStr == null) return;
      final userId = int.tryParse(userIdStr);
      if (userId == null) return;

      final unreadCount = await AlertsService.getUnreadCount();
      final recentAlerts = await AlertsService.getAlerts(userId: userId, limit: 5);
      
      setState(() {
        _unreadAlertCount = unreadCount;
        _recentAlerts = recentAlerts;
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() => _vehiclesLoading = true);
      final vehicles = await VehicleService.listVehicles();
      setState(() {
        _vehicles = vehicles;
        _vehiclesLoading = false;
      });
    } catch (e) {
      print('Error loading vehicles: $e');
      setState(() => _vehiclesLoading = false);
    }
  }

  void _showSettings() {
    showNotificationsSettingsSheet(
      context: context,
      unreadAlertCount: _unreadAlertCount,
      recentAlerts: _recentAlerts,
      onRefreshNotifications: _loadNotifications,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final scaffoldBg = theme.scaffoldBackgroundColor;

    // Theme-aware gradient that adapts to dark mode
    final gradientColors = isDark
        ? [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ]
        : [
            Colors.purple[50]!,
            Colors.blue[50]!,
            Colors.cyan[50]!,
          ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
        child: SafeArea(
            child: Column(
              children: [
              // Top Header with Privileges Toggle
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                Text(
                  "Welcome Back!",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Your mobility hub awaits",
                  style: theme.textTheme.bodyMedium,
                ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _togglePrivileges,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: isDark 
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedRotation(
                          turns: _isPrivilegesExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.menu,
                            color: theme.iconTheme.color,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                              ],
                            ),
              ),

              // Conditional Layout: Either Privileges (full height) or Main Content
              if (_isPrivilegesExpanded) ...[
                // Full Height Privileges Menu
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                      children: [
                          _buildPrivilegeItem(
                          "My Vehicles",
                          Icons.directions_car,
                            Colors.blue,
                          () => Navigator.push(
                            context,
                              MaterialPageRoute(builder: (_) => const VehicleListPage()),
                            ),
                          ),
                          _buildPrivilegeItem(
                            "Services & Booking",
                          Icons.miscellaneous_services,
                            Colors.green,
                          () => Navigator.pushNamed(context, "/services"),
                        ),
                          _buildPrivilegeItem(
                          "Insurance",
                          Icons.shield,
                            Colors.orange,
                          () => Navigator.pushNamed(context, "/insurance/dashboard"),
                        ),
                          _buildPrivilegeItem(
                          "Expenses",
                            Icons.account_balance_wallet,
                            Colors.purple,
                          () => Navigator.pushNamed(context, '/expenses'),
                        ),
                          _buildPrivilegeItem(
                          "Top Providers",
                          Icons.star_rate,
                            Colors.amber,
                          () => Navigator.push(
                            context,
                              MaterialPageRoute(builder: (_) => const ServicesProvidersPage()),
                            ),
                          ),
                          _buildPrivilegeItem(
                            "Alerts",
                          Icons.notifications,
                            Colors.red,
                          () => Navigator.pushNamed(context, '/alerts'),
                        ),
                          _buildPrivilegeItem(
                            "History",
                            Icons.history,
                            Colors.indigo,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HistoryPage()),
                            ),
                          ),
                          _buildPrivilegeItem(
                            "Loyalty Program",
                            Icons.stars,
                            Colors.amber,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UserLoyaltyPage()),
                            ),
                          ),
                          _buildPrivilegeItem(
                            "Profile & Settings",
                            Icons.settings,
                            Colors.teal,
                            () => _showSettings(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Main Content Area - Vehicle Dashboard (Core Focus)
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Alerts Section
                          if (_recentAlerts.isNotEmpty || _unreadAlertCount > 0) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? (_unreadAlertCount > 0 
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.blue.withOpacity(0.2))
                                    : (_unreadAlertCount > 0 
                                        ? Colors.orange[50] 
                                        : Colors.blue[50]),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? (_unreadAlertCount > 0 
                                          ? Colors.orange.withOpacity(0.4)
                                          : Colors.blue.withOpacity(0.4))
                                      : (_unreadAlertCount > 0 
                                          ? Colors.orange[200]! 
                                          : Colors.blue[200]!),
                                  width: 1.5,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(context, '/alerts'),
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications_active,
                                      color: _unreadAlertCount > 0 
                                          ? Colors.orange[isDark ? 400 : 700] 
                                          : Colors.blue[isDark ? 400 : 700],
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _unreadAlertCount > 0
                                                ? '$_unreadAlertCount unread alert${_unreadAlertCount > 1 ? 's' : ''}'
                                                : 'All caught up!',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: _unreadAlertCount > 0 
                                                  ? Colors.orange[isDark ? 300 : 900] 
                                                  : Colors.blue[isDark ? 300 : 900],
                                            ),
                                          ),
                                          if (_recentAlerts.isNotEmpty)
                                            Text(
                                              _recentAlerts.first.title,
                                              style: theme.textTheme.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: theme.iconTheme.color?.withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // My Vehicles Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Vehicles',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const VehicleListPage()),
                                ),
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Vehicles List
                          if (_vehiclesLoading)
                            const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_vehicles.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 64,
                                    color: theme.iconTheme.color?.withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No vehicles yet',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first vehicle to get started',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final added = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const VehicleFormPage()),
                                      );
                                      if (added == true) _loadVehicles();
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Vehicle'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._vehicles.take(3).map((vehicle) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withOpacity(0.3)
                                            : Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.blue[50],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.directions_car,
                                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                                          size: 28,
                                        ),
                                      ),
                                      title: Text(
                                        "${vehicle['make'] ?? 'Unknown'} ${vehicle['model'] ?? ''}",
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            "Plate: ${vehicle['plate'] ?? 'N/A'}",
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          if (vehicle['mileage'] != null)
                                            Text(
                                              "Mileage: ${vehicle['mileage']} km",
                                              style: theme.textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: theme.iconTheme.color?.withOpacity(0.5),
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const VehicleListPage()),
                                      ),
                                    ),
                                  ),
                                )),

                          if (_vehicles.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Center(
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const VehicleListPage()),
                                  ),
                                  child: Text('View ${_vehicles.length - 3} more vehicle${_vehicles.length - 3 > 1 ? 's' : ''}'),
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Quick Actions Section
                          Text(
                            'Quick Actions',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.miscellaneous_services,
                                  title: 'Book Service',
                                  color: Colors.green,
                                  onTap: () => Navigator.pushNamed(context, "/services"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.shield,
                                  title: 'Insurance',
                                  color: Colors.orange,
                                  onTap: () => Navigator.pushNamed(context, "/insurance/dashboard"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.account_balance_wallet,
                                  title: 'Expenses',
                                  color: Colors.purple,
                                  onTap: () => Navigator.pushNamed(context, '/expenses'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.history,
                                  title: 'History',
                                  color: Colors.indigo,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Social Hub Link (Secondary Feature)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.purple.withOpacity(0.2),
                                        Colors.pink.withOpacity(0.2),
                                      ]
                                    : [
                                        Colors.purple[50]!,
                                        Colors.pink[50]!,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.purple.withOpacity(0.4)
                                    : Colors.purple[200]!,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => SocialHubPage()),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: Colors.purple[isDark ? 400 : 700],
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Social Hub',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.purple[isDark ? 300 : 900],
                                              ),
                                            ),
                                            Text(
                                              'Connect with the community',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: theme.iconTheme.color?.withOpacity(0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivilegeItem(String title, IconData icon, Color color, VoidCallback onTap) {
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
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}
