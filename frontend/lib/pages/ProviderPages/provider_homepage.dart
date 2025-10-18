import 'package:flutter/material.dart';
import 'package:car_platform/pages/ProviderPages/provider_log_service_page.dart';
import 'package:car_platform/pages/ProviderPages/insurance_log_service_page.dart';
import 'package:car_platform/pages/ProviderPages/staff_management_page.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/user_context_service.dart';
import 'package:car_platform/components/preferences_popover.dart';
import 'package:car_platform/models/provider_category_config.dart';
import 'package:car_platform/models/frontend_category_grouping.dart';

class ProviderHomePage extends StatefulWidget {
  final String providerId;

  const ProviderHomePage({super.key, required this.providerId});

  @override
  State<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage> {
  String? _categoryName;
  String? _providerName;
  bool _isLoading = true;
  bool _showVerifiedOnly = false;
  ProviderCategoryConfig? _categoryConfig;
  FrontendCategoryGroup? _frontendGroup;

  @override
  void initState() {
    super.initState();
    _loadProviderDetails();
  }

  Future<void> _loadProviderDetails() async {
    try {
      final provider = await ProviderService.getProviderDetails(widget.providerId);
      setState(() {
        _categoryName = provider?['category']['name'];
        _providerName = provider?['name'];
        _categoryConfig = ProviderCategoryConfigs.getConfig(_categoryName ?? '');
        _frontendGroup = FrontendCategoryGroups.getGroupForBackendCategory(_categoryName ?? '');
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load provider details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final config = _categoryConfig ?? ProviderCategoryConfigs.getDefaultConfig(_categoryName ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(_providerName ?? "Provider Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Provider Settings",
            onPressed: _showProviderPreferences,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProviderDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Welcome Back 👋",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (_frontendGroup != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _frontendGroup!.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _frontendGroup!.color.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _frontendGroup!.icon,
                                      size: 14,
                                      color: _frontendGroup!.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _frontendGroup!.name,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: _frontendGroup!.color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _providerName ?? "Provider",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.welcomeMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dashboard Stats
              _buildStatsGrid(config.statCards),
              const SizedBox(height: 24),

              // Main Actions
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // Dynamic Quick Actions
              ...config.quickActions.map((action) => _buildQuickActionCard(action, config)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<StatCard> statCards) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(child: _buildStatCard(statCards[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(statCards[1])),
          ],
        ),
        const SizedBox(height: 12),
        // Second row
        Row(
          children: [
            Expanded(child: _buildStatCard(statCards[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(statCards[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(StatCard statCard) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(statCard.icon, size: 24, color: statCard.color),
            const SizedBox(height: 8),
            Text(
              statCard.title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              statCard.value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: statCard.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(QuickAction action, ProviderCategoryConfig config) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(action.icon, color: action.color),
            title: Text(action.title),
            subtitle: Text(action.subtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: action.isComingSoon
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${action.title} section coming soon...")),
                    );
                  }
                : () {
                    // Handle navigation based on route
                    if (action.route != null) {
                      Navigator.pushNamed(
                        context,
                        action.route!,
                        arguments: {'providerId': widget.providerId},
                      );
                    } else if (action.onTap != null) {
                      action.onTap!();
                    }
                  },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _showProviderPreferences() async {
    await showPreferencesPopover(
      context: context,
      recommendedOnly: _showVerifiedOnly,
      isPurchaseMode: false, // Provider mode
      onRecommendedOnlyChanged: (value) {
        setState(() => _showVerifiedOnly = value);
      },
      onApply: () {
        // Refresh provider data if needed
        _loadProviderDetails();
      },
      onLogout: () async {
        // Handle logout
        await _handleLogout();
      },
      onManageStaff: () {
        // Navigate to staff management page
        _navigateToStaffManagement();
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Clear user context and navigate to login
      await UserContextService.clearContext();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error during logout. Please try again.")),
        );
      }
    }
  }

  void _navigateToStaffManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffManagementPage(
          providerId: widget.providerId,
        ),
      ),
    );
  }
}
