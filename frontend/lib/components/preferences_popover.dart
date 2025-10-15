import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/user_context_service.dart';
import 'package:car_platform/services/alerts_service.dart';

class PreferencesPopover extends StatefulWidget {
  final bool recommendedOnly;
  final bool isPurchaseMode;
  final Function(bool) onRecommendedOnlyChanged;
  final VoidCallback? onApply;
  final VoidCallback? onLogout;
  final VoidCallback? onManageStaff;

  const PreferencesPopover({
    super.key,
    required this.recommendedOnly,
    required this.isPurchaseMode,
    required this.onRecommendedOnlyChanged,
    this.onApply,
    this.onLogout,
    this.onManageStaff,
  });

  @override
  State<PreferencesPopover> createState() => _PreferencesPopoverState();
}

class _PreferencesPopoverState extends State<PreferencesPopover> {
  late bool _recommendedOnly;

  @override
  void initState() {
    super.initState();
    _recommendedOnly = widget.recommendedOnly;
  }

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
          // Header (fixed)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 24, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  widget.isPurchaseMode ? "Purchase Preferences" : "Booking Preferences",
                  style: const TextStyle(
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
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                if (!widget.isPurchaseMode) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.group, color: Colors.green),
                    title: const Text("Manage Staff"),
                    subtitle: const Text("Add and manage your team members"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: widget.onManageStaff ?? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Staff management coming soon!")),
                      );
                    },
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout"),
                  subtitle: const Text("Sign out of your account"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLogoutDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Mode-specific preferences
          if (widget.isPurchaseMode) ...[
            // Purchase mode specific preferences
            const Text(
              "Purchase Settings",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.orange),
                title: const Text("Default Purchase Type"),
                subtitle: const Text("Set your preferred purchase method"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Purchase type preferences coming soon!")),
                  );
                },
              ),
            ),
          ] else ...[
            // Service booking mode specific preferences
            const Text(
              "Service Settings",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.build_circle, color: Colors.blue),
                title: const Text("Service Categories"),
                subtitle: const Text("Manage your preferred service types"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Service category preferences coming soon!")),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Filtering Preferences
          Text(
            widget.isPurchaseMode ? "Supplier Filtering" : "Provider Filtering",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: Text(widget.isPurchaseMode 
                  ? "Show Verified Suppliers Only" 
                  : "Show Recommended Providers Only"),
              subtitle: Text(widget.isPurchaseMode
                  ? "Filter to show only verified parts suppliers"
                  : "Providers that offer ALL selected services"),
              value: _recommendedOnly,
              onChanged: (v) => setState(() => _recommendedOnly = v),
            ),
          ),
          const SizedBox(height: 16),
          
          // Additional Preferences (for future expansion)
          const Text(
            "Additional Options",
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
          const SizedBox(height: 8),
          if (!widget.isPurchaseMode) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule, color: Colors.purple),
                title: const Text("Default Time Slots"),
                subtitle: const Text("Set preferred booking times"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Future: Show time slot preferences
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Time slot preferences coming soon!")),
                  );
                },
              ),
            ),
          ] else ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.green),
                title: const Text("Delivery Preferences"),
                subtitle: const Text("Set default delivery options"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Future: Show delivery preferences
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Delivery preferences coming soon!")),
                  );
                },
              ),
            ),
          ],
          
                ],
              ),
            ),
          ),
          
          // Apply Button (fixed at bottom)
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Apply changes to parent widget
                  widget.onRecommendedOnlyChanged(_recommendedOnly);
                  
                  // Call additional apply callback if provided
                  widget.onApply?.call();
                  
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Apply Preferences",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

    final Map<String, dynamic> byType = { for (final p in prefs) p['alert_type']: p };
    bool insuranceEnabled = (byType['insurance_expiry']?['is_enabled'] ?? true) as bool;
    bool serviceEnabled = (byType['service_due']?['is_enabled'] ?? true) as bool;
    final Set<String> insuranceChannels = Set<String>.from(byType['insurance_expiry']?['channels'] ?? ['in_app']);
    final Set<String> serviceChannels = Set<String>.from(byType['service_due']?['channels'] ?? ['in_app']);

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
                Navigator.of(context).pop(); // Close preferences popover
                
                // Call logout callback if provided
                widget.onLogout?.call();
                
                // Fallback: direct logout if no callback provided
                if (widget.onLogout == null) {
                  await AuthService.logout();
                  UserContextService.clearContext();
                  
                  // Navigate to login page
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
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

/// Helper function to show the preferences popover
Future<void> showPreferencesPopover({
  required BuildContext context,
  required bool recommendedOnly,
  required bool isPurchaseMode,
  required Function(bool) onRecommendedOnlyChanged,
  VoidCallback? onApply,
  VoidCallback? onLogout,
  VoidCallback? onManageStaff,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => PreferencesPopover(
      recommendedOnly: recommendedOnly,
      isPurchaseMode: isPurchaseMode,
      onRecommendedOnlyChanged: onRecommendedOnlyChanged,
      onApply: onApply,
      onLogout: onLogout,
      onManageStaff: onManageStaff,
    ),
  );
}
