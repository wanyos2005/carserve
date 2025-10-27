import 'package:flutter/material.dart';
import 'package:driveon_car_platform/pages/social_media/social_hub_page.dart';
import 'package:driveon_car_platform/services/provider_service.dart';
import 'package:driveon_car_platform/services/provider_stats_service.dart';
import 'package:driveon_car_platform/models/provider_category_config.dart';
import 'package:driveon_car_platform/models/frontend_category_grouping.dart';

class ProviderHomePage extends StatefulWidget {
  final String providerId;

  const ProviderHomePage({super.key, required this.providerId});

  @override
  State<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage> with TickerProviderStateMixin {
  String? _categoryName;
  String? _providerName;
  bool _isLoading = true;
  bool _isPrivilegesExpanded = false;
  ProviderCategoryConfig? _categoryConfig;
  FrontendCategoryGroup? _frontendGroup;
  List<StatCard> _dynamicStatCards = [];
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderDetails();
  }

  void _togglePrivileges() {
    setState(() {
      _isPrivilegesExpanded = !_isPrivilegesExpanded;
    });
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
      
      // Load real-time stats after provider details are loaded
      await _loadProviderStats();
    } catch (e) {
      debugPrint("Failed to load provider details: $e");
      setState(() {
        _isLoading = false;
        _statsLoading = false;
      });
    }
  }

  Future<void> _loadProviderStats() async {
    try {
      final stats = await ProviderStatsService.getProviderStats(widget.providerId);
      if (stats != null) {
        // Update the stats cache
        ProviderCategoryConfigs.updateStatsCache(widget.providerId, stats);
        
        // Get dynamic stat cards based on real data
        final dynamicStats = ProviderCategoryConfigs.getDynamicStatCards(
          widget.providerId, 
          _categoryName ?? ''
        );
        
        setState(() {
          _dynamicStatCards = dynamicStats;
          _statsLoading = false;
        });
      } else {
        // Fallback to default stats if API fails
        setState(() {
          _dynamicStatCards = ProviderCategoryConfigs.getDefaultStatCards(_categoryName ?? '');
          _statsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to load provider stats: $e");
      setState(() {
        _dynamicStatCards = ProviderCategoryConfigs.getDefaultStatCards(_categoryName ?? '');
        _statsLoading = false;
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
              // Top Header with Provider Info and Menu Toggle
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
                          _providerName ?? "Provider",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_frontendGroup != null) ...[
                          const SizedBox(height: 4),
                          Container(
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
                                  size: 12,
                                  color: _frontendGroup!.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _frontendGroup!.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _frontendGroup!.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                // Full Height Provider Dashboard
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Provider Dashboard Stats
                          _buildStatsGrid(_dynamicStatCards.isNotEmpty ? _dynamicStatCards : config.statCards, isLoading: _statsLoading),
                          const SizedBox(height: 24),

                          // Quick Actions
                          Text(
                            "Quick Actions",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...config.quickActions.map((action) => _buildQuickActionCard(action, config)).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Main Content Area - Provider Hub (Clean & Modern)
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
                            _frontendGroup?.icon ?? Icons.business,
                            size: 100,
                            color: _frontendGroup?.color ?? Colors.blue[600],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            "Your Business Hub",
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            config.welcomeMessage,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Dashboard Button
                              ElevatedButton(
                                onPressed: _togglePrivileges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _frontendGroup?.color ?? Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.dashboard, size: 24),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Dashboard",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Social Hub Button
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SocialHubPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 24),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Social Hub",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildStatsGrid(List<StatCard> statCards, {bool isLoading = false}) {
    return Column(
      children: [
        // Header with refresh button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Statistics",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              onPressed: isLoading ? null : _loadProviderStats,
              icon: isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, color: Colors.blue[600]),
              tooltip: "Refresh Statistics",
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Stats grid
        Column(
          children: [
            // First row
            Row(
              children: [
                Expanded(child: _buildStatCard(statCards[0], isLoading: isLoading)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(statCards[1], isLoading: isLoading)),
              ],
            ),
            const SizedBox(height: 12),
            // Second row
            Row(
              children: [
                Expanded(child: _buildStatCard(statCards[2], isLoading: isLoading)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(statCards[3], isLoading: isLoading)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(StatCard statCard, {bool isLoading = false}) {
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
            isLoading 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(statCard.color),
                  ),
                )
              : Text(
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
    return GestureDetector(
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.subtitle,
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
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }


}
