import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/user_context_service.dart';
import 'package:car_platform/services/alerts_service.dart';
import 'vehicle_list_page.dart';
import 'services_providers_page.dart';
import 'login_page.dart';
import 'history_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Header Section - Modern gradient design
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white70,
                  Colors.grey[100]!,
                ],
              ),
            ),
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.directions_car, color: Colors.grey[800], size: 48),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/alerts'),
                      child: FutureBuilder<int>(
                        future: _getUnreadCount(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.notifications, color: Colors.grey[800], size: 24),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                    ),
                                    child: Text(
                                      count > 99 ? '99+' : '$count',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Welcome Back!",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Your car companion is here.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                // Quick stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard("Vehicles", "2", Icons.directions_car, Colors.grey[800]!),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard("Services", "5", Icons.build, Colors.grey[800]!),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard("Insurance", "1", Icons.security, Colors.grey[800]!),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.35,
            maxChildSize: 0.95,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Search bar - Enhanced design
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search for services, providers...",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.search, color: Colors.red[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Promotions - Enhanced design
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[100]!, Colors.orange[50]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.local_offer, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Special Offer!",
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                Text(
                                  "20% off on servicing this week",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6 Navigation Cards in 2 Rows
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _navCard(
                          context,
                          "My Vehicles",
                          Icons.directions_car,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VehicleListPage()),
                          ),
                        ),
                        _navCard(
                          context,
                          "Services",
                          Icons.miscellaneous_services,
                          () => Navigator.pushNamed(context, "/services"),
                        ),
                        _navCard(
                          context,
                          "Insurance",
                          Icons.shield,
                          () => Navigator.pushNamed(context, "/insurance/dashboard"),
                        ),
                        _navCard(
                          context,
                          "Expenses",
                          Icons.shield,
                          () => Navigator.pushNamed(context, '/expenses'),
                        ),
                        _navCard(
                          context,
                          "Top Providers",
                          Icons.star_rate,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ServicesProvidersPage()),
                          ),
                        ),
                        _navCard(
                          context,
                          "Alerts & More",
                          Icons.notifications,
                          () => Navigator.pushNamed(context, '/alerts'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Featured Services Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Featured Services",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, "/services"),
                          child: Text(
                            "View All",
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Featured services horizontal scroll
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFeaturedService("Oil Change", Icons.oil_barrel, Colors.orange, "From KSh 2,500"),
                          _buildFeaturedService("Brake Service", Icons.car_repair, Colors.red, "From KSh 4,000"),
                          _buildFeaturedService("Tire Service", Icons.tire_repair, Colors.blue, "From KSh 1,500"),
                          _buildFeaturedService("AC Service", Icons.ac_unit, Colors.cyan, "From KSh 3,000"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Quick Actions Header
                    Text(
                      "Quick Actions",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Quick Actions
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickAction(
                            context,
                            "Book Service",
                            Icons.add_circle,
                            onTap: () {
                              Navigator.pushNamed(context, '/services');
                            },
                          ),
                          _quickAction(
                            context,
                            "History",
                            Icons.history,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HistoryPage()),
                              );
                            },
                          ),
                          _quickAction(context, "Support", Icons.support_agent),
                          _quickAction(
                            context,
                            "Debug",
                            Icons.bug_report,
                            onTap: () async {
                              // Debug: Check what the backend is actually returning
                              final userData = await AuthService.getMe();
                              if (userData != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Backend data: ${userData.toString()}"),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No user data received")),
                                );
                              }
                            },
                          ),
                          _quickAction(
                            context,
                            "Refresh",
                            Icons.refresh,
                            onTap: () async {
                              // Refresh user context to check for admin role changes
                              final newContext = await UserContextService.refreshContext();
                              if (newContext != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Context refreshed. User type: ${newContext.userType.name}"),
                                  ),
                                );
                                // Force rebuild by navigating to the same page
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomePage()),
                                );
                              }
                            },
                          ),
                          _quickAction(
                            context,
                            "Logout",
                            Icons.logout,
                            onTap: () {
                              AuthService.logout().then((_) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginPage()),
                                );
                              });
                            },
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // Footer
      bottomNavigationBar: Container(
        height: 50,
        color: colorScheme.surface,
        alignment: Alignment.center,
        child: Text(
          "© 2025 Car Platform - v1.0.0",
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Future<int> _getUnreadCount() async {
    final userIdStr = UserContextService.currentContext?.id;
    if (userIdStr == null) return 0;
    final userId = int.tryParse(userIdStr);
    if (userId == null) return 0;
    return AlertsService.getUnreadCount(userId);
  }

  // Enhanced Nav Card - Clean design like enhanced service selector
  Widget _navCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    // Color mapping for different services
    Color getCardColor(String title) {
      switch (title.toLowerCase()) {
        case 'my vehicles':
          return Colors.blue[100]!;
        case 'services':
          return Colors.green[100]!;
        case 'insurance':
          return Colors.orange[100]!;
        case 'expenses':
          return Colors.purple[100]!;
        case 'top providers':
          return Colors.amber[100]!;
        case 'alerts & more':
          return Colors.red[100]!;
        default:
          return Colors.grey[100]!;
      }
    }
    
    Color getIconColor(String title) {
      switch (title.toLowerCase()) {
        case 'my vehicles':
          return Colors.blue[800]!;
        case 'services':
          return Colors.green[800]!;
        case 'insurance':
          return Colors.orange[800]!;
        case 'expenses':
          return Colors.purple[800]!;
        case 'top providers':
          return Colors.amber[800]!;
        case 'alerts & more':
          return Colors.red[800]!;
        default:
          return Colors.grey[800]!;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 28,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getCardColor(title),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: getIconColor(title)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Quick Action - Clean design
  Widget _quickAction(BuildContext context, String label, IconData icon,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // New stat card for header
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Featured service card
  Widget _buildFeaturedService(String title, IconData icon, Color color, String price) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
