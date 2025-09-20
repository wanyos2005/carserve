import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'vehicle_list_page.dart';
import 'services_providers_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient header (abyss + red)
          Container(
            width: double.infinity,
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D0D0F), // abyss black
                  Color(0xFF0A0E1A), // abyss blue undertone
                  Color(0xFF8B0000), // red glow
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.directions_car, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Your car companion is here.",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Scrollable bottom sheet content
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.65,
            maxChildSize: 0.95,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D0D0F), // abyss black
                      Color(0xFF0A0E1A), // abyss blue undertone
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black87,
                      offset: Offset(0, -4),
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
                        prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick navigation cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _navCard(
                          context,
                          "Service Providers",
                          Icons.build_circle,
                          Colors.redAccent,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ServicesProvidersPage()),
                          ),
                        ),
                        _navCard(
                          context,
                          "My Vehicles",
                          Icons.directions_car,
                          Colors.white,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VehicleListPage()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Promotions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.local_offer, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "🔥 Special offer: 20% off on servicing this week!",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick actions
                    const Text(
                      "Quick Actions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _quickAction(Icons.add_circle, "Book Service"),
                        _quickAction(Icons.history, "History"),
                        _quickAction(Icons.support_agent, "Support"),
                        _quickAction(Icons.logout, "Logout", onTap: () {
                          AuthService.logout().then((_) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                            );
                          });
                        }),
                      ],
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
        color: Colors.black,
        alignment: Alignment.center,
        child: const Text(
          "© 2025 Car Platform - v1.0.0",
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _navCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            child: Icon(icon, color: Colors.redAccent),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
