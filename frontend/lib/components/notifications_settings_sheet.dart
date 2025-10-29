import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/services/alerts_service.dart';
import 'package:driveon_car_platform/services/auth_service.dart';

class NotificationsSettingsSheet extends StatefulWidget {
  final int? unreadAlertCount;
  final List<Alert> recentAlerts;
  final VoidCallback? onRefreshNotifications;

  const NotificationsSettingsSheet({
    super.key,
    this.unreadAlertCount = 0,
    this.recentAlerts = const [],
    this.onRefreshNotifications,
  });

  @override
  State<NotificationsSettingsSheet> createState() => _NotificationsSettingsSheetState();
}

class _NotificationsSettingsSheetState extends State<NotificationsSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.notifications, size: 24, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  "Notifications & Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TabBar(
                      indicator: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: "Notifications"),
                        Tab(text: "Settings"),
                      ],
                    ),
                  ),
                  
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildNotificationsTab(),
                        _buildSettingsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build notifications tab
  Widget _buildNotificationsTab() {
    if (widget.recentAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see alerts about your vehicles and services here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.recentAlerts.length,
      itemBuilder: (context, index) {
        final alert = widget.recentAlerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  /// Build settings tab
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          const Text(
            "Profile & Account",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: const Text("Profile Information"),
                  subtitle: Text("Logged in as: ${UserContextService.getDisplayName()}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile management coming soon!")),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout"),
                  subtitle: const Text("Sign out of your account"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLogoutDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Notification Preferences
          const Text(
            "Notification Preferences",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text("Alert Preferences"),
              subtitle: const Text("Configure alert types and channels"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _openAlertPreferences,
            ),
          ),
          const SizedBox(height: 16),
          
          // Social Media Preferences
          const Text(
            "Social Media Settings",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.green),
                  title: const Text("Privacy Settings"),
                  subtitle: const Text("Control who can see your posts"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Privacy settings coming soon!")),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text("Blocked Users"),
                  subtitle: const Text("Manage blocked users"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Blocked users management coming soon!")),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: const Text("Report Issues"),
                  subtitle: const Text("Report bugs or inappropriate content"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Report system coming soon!")),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // App Settings
          const Text(
            "App Settings",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode, color: Colors.purple),
                  title: const Text("Theme"),
                  subtitle: const Text("Light / Dark mode"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Theme settings coming soon!")),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: const Text("Language"),
                  subtitle: const Text("English"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Language settings coming soon!")),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage, color: Colors.green),
                  title: const Text("Storage & Cache"),
                  subtitle: const Text("Manage app storage"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Storage management coming soon!")),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual alert card
  Widget _buildAlertCard(Alert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAlertColor(alert.type),
          child: Icon(
            _getAlertIcon(alert.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          alert.title,
          style: TextStyle(
            fontWeight: alert.isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  alert.typeDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(alert.priority),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.priorityText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimeAgo(alert.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: alert.isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          if (alert.isUnread) {
            await AlertsService.markAsRead(alert.id);
            widget.onRefreshNotifications?.call();
          }
          
          if (alert.actionUrl != null) {
            // Handle action URL if needed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Action: ${alert.actionText ?? "View Details"}')),
            );
          }
        },
      ),
    );
  }

  /// Get alert color based on type
  Color _getAlertColor(String type) {
    switch (type) {
      case 'insurance_expiry': return Colors.red;
      case 'service_due': return Colors.orange;
      case 'app_download_prompt': return Colors.blue;
      case 'maintenance_reminder': return Colors.green;
      case 'booking_confirmation': return Colors.purple;
      case 'payment_reminder': return Colors.amber;
      default: return Colors.grey;
    }
  }

  /// Get alert icon based on type
  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'insurance_expiry': return Icons.security;
      case 'service_due': return Icons.build;
      case 'app_download_prompt': return Icons.download;
      case 'maintenance_reminder': return Icons.schedule;
      case 'booking_confirmation': return Icons.check_circle;
      case 'payment_reminder': return Icons.payment;
      default: return Icons.notifications;
    }
  }

  /// Get priority color
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }

  /// Format time ago
  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Open alert preferences dialog
  Future<void> _openAlertPreferences() async {
    final userIdStr = UserContextService.currentContext?.id;
    if (userIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to manage alert preferences.")),
      );
      return;
    }
    final userId = int.tryParse(userIdStr);
    if (userId == null) return;

    final prefs = await AlertsService.getPreferences(userId);

    final Map<String, AlertPreference> byType = { for (final p in prefs) p.alertType: p };
    bool insuranceEnabled = byType['insurance_expiry']?.isEnabled ?? true;
    bool serviceEnabled = byType['service_due']?.isEnabled ?? true;
    final Set<String> insuranceChannels = Set<String>.from(byType['insurance_expiry']?.channels ?? ['in_app']);
    final Set<String> serviceChannels = Set<String>.from(byType['service_due']?.channels ?? ['in_app']);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Alert Preferences'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Insurance Expiry'),
                  SwitchListTile(
                    value: insuranceEnabled,
                    onChanged: (v) => setLocal(() => insuranceEnabled = v),
                    title: const Text('Enabled'),
                  ),
                  Wrap(
                    spacing: 8,
                    children: _channelChips(insuranceChannels, (c, on) => setLocal(() {
                      on ? insuranceChannels.add(c) : insuranceChannels.remove(c);
                    })),
                  ),
                  const SizedBox(height: 12),
                  const Text('Service Due'),
                  SwitchListTile(
                    value: serviceEnabled,
                    onChanged: (v) => setLocal(() => serviceEnabled = v),
                    title: const Text('Enabled'),
                  ),
                  Wrap(
                    spacing: 8,
                    children: _channelChips(serviceChannels, (c, on) => setLocal(() {
                      on ? serviceChannels.add(c) : serviceChannels.remove(c);
                    })),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await AlertsService.upsertPreference(
                      userId: userId,
                      alertType: 'insurance_expiry',
                      isEnabled: insuranceEnabled,
                      channels: insuranceChannels.toList(),
                    );
                    await AlertsService.upsertPreference(
                      userId: userId,
                      alertType: 'service_due',
                      isEnabled: serviceEnabled,
                      channels: serviceChannels.toList(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert preferences saved successfully!')),
                      );
                      Navigator.pop(ctx);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving preferences: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              )
            ],
          ),
        );
      },
    );
  }

  /// Build channel chips for alert preferences
  List<Widget> _channelChips(Set<String> selected, void Function(String, bool) onChanged) {
    const channels = ['in_app', 'email', 'sms'];
    return channels.map((c) {
      final isSelected = selected.contains(c);
      return FilterChip(
        label: Text(c.toUpperCase()),
        selected: isSelected,
        onSelected: (v) => onChanged(c, v),
      );
    }).toList();
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text("Logout"),
            ],
          ),
          content: const Text("Are you sure you want to logout? You'll need to sign in again to access your account."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close settings sheet
                
                // Perform logout
                await AuthService.logout();
                UserContextService.clearContext();
                
                // Navigate to login page
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}

/// Helper function to show the notifications & settings sheet
Future<void> showNotificationsSettingsSheet({
  required BuildContext context,
  int unreadAlertCount = 0,
  List<Alert> recentAlerts = const [],
  VoidCallback? onRefreshNotifications,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => NotificationsSettingsSheet(
      unreadAlertCount: unreadAlertCount,
      recentAlerts: recentAlerts,
      onRefreshNotifications: onRefreshNotifications,
    ),
  );
}
