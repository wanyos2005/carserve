import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'vehicle_list_page.dart';
import 'services_providers_page.dart';
import 'service_provider_management_page.dart';
import 'login_page.dart';
import 'history_page.dart';
import 'booking_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Plain color header
          Container(
            width: double.infinity,
            height: 280,
            color: colorScheme.primary,
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.directions_car,
                    color: colorScheme.onPrimary, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Welcome Back!",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                Text(
                  "Your car companion is here.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.65,
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
                    // Search bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search for services, providers...",
                        prefixIcon: Icon(Icons.search,
                            color: colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick nav cards
                    Row(
                      children: [
                        Expanded(
                          child: _navCard(
                            context,
                            "Service Providers",
                            Icons.build_circle,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ServicesProvidersPage()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _navCard(
                            context,
                            "My Vehicles",
                            Icons.directions_car,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const VehicleListPage()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Promotions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "🔥 Special offer: 20% off on servicing this week!",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick actions
                    Text(
                      "Quick Actions",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickAction(
                            context,
                            "Book Service",
                            Icons.add_circle,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BookingPage()),
                              );
                            },
                          ),
                          _quickAction(
                            context,
                            "History",
                            Icons.history,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const HistoryPage()),
                              );
                            },
                          ),
                          _quickAction(context, "Support", Icons.support_agent),
                          _quickAction(
                            context,
                            "Logout",
                            Icons.logout,
                            onTap: () {
                              AuthService.logout().then((_) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                );
                              });
                            },
                          ),
                          _quickAction(
                            context,
                            "Admin Functions",
                            Icons.settings,
                            onTap: () {
                              Navigator.pushNamed(context, "/providers");
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

  // Nav card
  Widget _navCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: colorScheme.surface,
        child: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick action
  Widget _quickAction(BuildContext context, String label, IconData icon,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
