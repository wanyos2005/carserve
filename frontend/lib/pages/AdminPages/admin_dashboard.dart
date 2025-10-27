import 'package:flutter/material.dart';
import 'package:driveon_car_platform/pages/admin/provider_user_link_page.dart';
import 'package:driveon_car_platform/pages/provider_management_page.dart';
import 'package:driveon_car_platform/pages/AdminPages/service_management_page.dart';
import 'package:driveon_car_platform/pages/AdminPages/admin_management_page.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "User Profile",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Logged in as: ${UserContextService.getDisplayName()}"),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Admin Panel 🔧",
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Welcome, ${UserContextService.getDisplayName()}",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage the platform, users, providers, and services",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Admin Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total Users",
                    "1,234",
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    "Active Providers",
                    "89",
                    Icons.business,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Service Categories",
                    "12",
                    Icons.category,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    "Pending Reviews",
                    "23",
                    Icons.pending_actions,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Admin Functions
            Text(
              "Administrative Functions",
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // User Management
            Card(
              child: ListTile(
                leading: const Icon(Icons.link, color: Colors.blue),
                title: const Text("Link User to Provider"),
                subtitle: const Text("Associate users with service providers"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProviderUserLinkPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Provider Management
            Card(
              child: ListTile(
                leading: const Icon(Icons.business, color: Colors.green),
                title: const Text("Provider Management"),
                subtitle: const Text("Manage service providers and categories"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProviderManagementPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Service Management
            Card(
              child: ListTile(
                leading: const Icon(Icons.miscellaneous_services, color: Colors.orange),
                title: const Text("Service Management"),
                subtitle: const Text("Manage global services and categories"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceManagementPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // System Settings
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text("System Settings"),
                subtitle: const Text("Configure platform settings and preferences"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("System settings coming soon...")),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Analytics & Reports
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics, color: Colors.purple),
                title: const Text("Analytics & Reports"),
                subtitle: const Text("View platform usage and performance metrics"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Analytics dashboard coming soon...")),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Admin Management
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
                title: const Text("Admin Management"),
                subtitle: const Text("Manage admin users and privileges"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminManagementPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // User Management
            Card(
              child: ListTile(
                leading: const Icon(Icons.people_alt, color: Colors.indigo),
                title: const Text("User Management"),
                subtitle: const Text("Manage user accounts and permissions"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User management coming soon...")),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              "Quick Actions",
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement bulk operations
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bulk operations coming soon...")),
                      );
                    },
                    icon: const Icon(Icons.batch_prediction),
                    label: const Text("Bulk Operations"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement system backup
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("System backup coming soon...")),
                      );
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text("System Backup"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
