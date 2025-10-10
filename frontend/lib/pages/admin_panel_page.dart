import 'package:flutter/material.dart';
import 'provider_management_page.dart';
import 'service_management_page.dart';
import 'admin/provider_user_link_page.dart';


class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Admin Actions",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 20),

            // Navigation Cards
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _adminCard(
                  context,
                  "Manage Providers",
                  Icons.business,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProviderManagementPage()),
                  ),
                ),
                
                _adminCard(
                  context,
                  "Link Users to Providers",
                  Icons.link,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProviderUserLinkPage()),
                  ),
                ),

                _adminCard(
                  context,
                  "Manage Services",
                  Icons.build,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ServiceManagementPage()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 30,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
