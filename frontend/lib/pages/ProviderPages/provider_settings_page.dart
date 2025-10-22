import 'package:flutter/material.dart';
import 'package:car_platform/pages/AdminPages/edit_our_services_page.dart';
import 'package:car_platform/pages/manage_templates_page.dart';
import 'package:car_platform/services/auth_service.dart';

class ProviderSettingsPage extends StatelessWidget {
  final String providerId;
  
  const ProviderSettingsPage({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Provider Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your provider account and services',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),

                // Settings Options
                Expanded(
                  child: ListView(
                    children: [
                      // Edit Provider Card
                      _buildSettingsCard(
                        context,
                        title: 'Edit Our Services',
                        subtitle: 'Manage your services, pricing, and service requirements',
                        icon: Icons.edit,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditOurServicesPage(providerId: providerId),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Manage Templates Card
                      _buildSettingsCard(
                        context,
                        title: 'Manage Templates',
                        subtitle: 'Create and manage service templates for quick booking',
                        icon: Icons.dynamic_form,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageTemplatesPage(providerId: providerId),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Account Settings Card
                      _buildSettingsCard(
                        context,
                        title: 'Account Settings',
                        subtitle: 'Manage your account preferences and notifications',
                        icon: Icons.account_circle,
                        color: Colors.orange,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account settings coming soon!')),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Logout Card
                      _buildSettingsCard(
                        context,
                        title: 'Logout',
                        subtitle: 'Sign out of your provider account',
                        icon: Icons.logout,
                        color: Colors.red,
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/welcome',
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
