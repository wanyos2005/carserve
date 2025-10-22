import 'package:flutter/material.dart';
import 'vehicle_list_page.dart';
import 'services_providers_page.dart';
import 'history_page.dart';
import 'social_media/social_hub_page.dart';
import '../components/preferences_popover.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isPrivilegesExpanded = false;

  void _togglePrivileges() {
    setState(() {
      _isPrivilegesExpanded = !_isPrivilegesExpanded;
    });
  }

  void _showPreferencesPopover() {
    showPreferencesPopover(
      context: context,
      recommendedOnly: false, // Default value
      isPurchaseMode: false, // This is a service booking mode
      onRecommendedOnlyChanged: (value) {
        // Handle preference changes if needed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Preference updated: $value")),
        );
      },
      onApply: () {
        // Handle apply action
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preferences applied successfully!")),
        );
      },
      onLogout: () {
        // Handle logout - this will be called by the preferences popover
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              Colors.purple[50]!,
              Colors.blue[50]!,
              Colors.cyan[50]!,
                ],
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
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                          "Your mobility hub awaits",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _togglePrivileges,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 2),
                    ),
                  ],
                ),
                        child: AnimatedRotation(
                          turns: _isPrivilegesExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.menu,
                            color: Colors.grey[800],
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          color: Colors.black.withOpacity(0.1),
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
                            "Profile & Settings",
                            Icons.settings,
                            Colors.teal,
                            () => _showPreferencesPopover(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Main Content Area - Social Hub (Clean & Minimalistic)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 100,
                            color: Colors.red[600],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            "Your Social Hub",
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Connect, Share, Discover",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SocialHubPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              "Explore Community",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
              title,
                style: const TextStyle(
                  fontSize: 16,
                fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

}
