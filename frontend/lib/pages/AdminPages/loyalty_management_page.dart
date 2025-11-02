import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/loyalty_service.dart';
import 'package:driveon_car_platform/services/api_service.dart';

class LoyaltyManagementPage extends StatefulWidget {
  const LoyaltyManagementPage({super.key});

  @override
  State<LoyaltyManagementPage> createState() => _LoyaltyManagementPageState();
}

class _LoyaltyManagementPageState extends State<LoyaltyManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data
  List<dynamic>? _rules;
  List<dynamic>? _rewards;
  List<dynamic>? _participatingProviders;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rules = await ApiService.get('/loyalty/rules');
      final rewards = await ApiService.get('/loyalty/rewards');
      final providers = await LoyaltyService.getParticipatingProviders();
      
      setState(() {
        _rules = rules is List ? rules : [];
        _rewards = rewards is List ? rewards : [];
        _participatingProviders = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.rule), text: 'Rules'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Rewards'),
            Tab(icon: Icon(Icons.business), text: 'Providers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRulesTab(),
                  _buildRewardsTab(),
                  _buildProvidersTab(),
                ],
              ),
            ),
    );
  }

  // ============ Rules Tab ============
  Widget _buildRulesTab() {
    if (_rules == null || _rules!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rule, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No rules found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showCreateRuleDialog,
              child: const Text('Create Rule'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loyalty Rules (${_rules!.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: _showCreateRuleDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Rule'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _rules!.length,
            itemBuilder: (context, index) {
              final rule = _rules![index];
              final isDefault = rule['name']?.toString().toLowerCase().contains('default') ?? false;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isDefault ? Icons.star : Icons.rule,
                    color: isDefault ? Colors.amber : Colors.blue,
                  ),
                  title: Text(rule['name'] ?? 'Unnamed Rule'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Multiplier: ${rule['multiplier'] ?? 1.0}x'),
                      Text('Priority: ${rule['priority'] ?? 0}'),
                      Text(
                        rule['is_active'] == true ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: rule['is_active'] == true ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      if (!isDefault)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              rule['is_active'] == true ? Icons.pause : Icons.play_arrow,
                            ),
                            const SizedBox(width: 8),
                            Text(rule['is_active'] == true ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteRule(rule['id']);
                      } else if (value == 'toggle') {
                        _toggleRule(rule['id'], !(rule['is_active'] == true));
                      } else if (value == 'edit') {
                        _showEditRuleDialog(rule);
                      }
                    },
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ Rewards Tab ============
  Widget _buildRewardsTab() {
    if (_rewards == null || _rewards!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No rewards found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showCreateRewardDialog,
              child: const Text('Create Reward'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rewards (${_rewards!.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: _showCreateRewardDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Reward'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _rewards!.length,
            itemBuilder: (context, index) {
              final reward = _rewards![index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.card_giftcard, color: Colors.purple),
                  title: Text(reward['name'] ?? 'Unnamed Reward'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Points Required: ${reward['points_required'] ?? 0}'),
                      Text('Min Tier: ${reward['min_tier'] ?? 'Any'}'),
                      Text(
                        reward['is_active'] == true ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: reward['is_active'] == true ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              reward['is_active'] == true ? Icons.pause : Icons.play_arrow,
                            ),
                            const SizedBox(width: 8),
                            Text(reward['is_active'] == true ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteReward(reward['id']);
                      } else if (value == 'toggle') {
                        _toggleReward(reward['id'], !(reward['is_active'] == true));
                      } else if (value == 'edit') {
                        _showEditRewardDialog(reward);
                      }
                    },
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ Providers Tab ============
  Widget _buildProvidersTab() {
    if (_participatingProviders == null || _participatingProviders!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No participating providers'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Participating Providers (${_participatingProviders!.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _participatingProviders!.length,
            itemBuilder: (context, index) {
              final provider = _participatingProviders![index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle,
                    color: provider['is_participating'] == true ? Colors.green : Colors.grey,
                  ),
                  title: Text('Provider: ${provider['provider_id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tier: ${provider['participation_tier'] ?? 'N/A'}'),
                      Text('Multiplier: ${provider['point_multiplier'] ?? 1.0}x'),
                      Text('Billing: ${provider['billing_plan'] ?? 'N/A'}'),
                      Text('Points This Month: ${provider['points_awarded_this_month'] ?? 0}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showProviderDetails(provider),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ Dialogs ============
  Future<void> _showCreateRuleDialog() async {
    final nameController = TextEditingController();
    final multiplierController = TextEditingController(text: '1.0');
    final priorityController = TextEditingController(text: '0');
    final basePointsController = TextEditingController(text: '0.01');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Loyalty Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Rule Name'),
              ),
              TextField(
                controller: basePointsController,
                decoration: const InputDecoration(labelText: 'Base Points per KES'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: multiplierController,
                decoration: const InputDecoration(labelText: 'Multiplier'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: priorityController,
                decoration: const InputDecoration(labelText: 'Priority (higher = first)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.post('/loyalty/rules', {
                  'name': nameController.text,
                  'base_points_per_kes': double.tryParse(basePointsController.text) ?? 0.01,
                  'multiplier': double.tryParse(multiplierController.text) ?? 1.0,
                  'priority': int.tryParse(priorityController.text) ?? 0,
                  'is_active': true,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRuleDialog(Map<String, dynamic> rule) async {
    final nameController = TextEditingController(text: rule['name']?.toString() ?? '');
    final multiplierController = TextEditingController(text: rule['multiplier']?.toString() ?? '1.0');
    final priorityController = TextEditingController(text: rule['priority']?.toString() ?? '0');
    final basePointsController = TextEditingController(text: rule['base_points_per_kes']?.toString() ?? '0.01');
    final isActive = rule['is_active'] == true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Loyalty Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Rule Name'),
                ),
                TextField(
                  controller: basePointsController,
                  decoration: const InputDecoration(labelText: 'Base Points per KES'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: multiplierController,
                  decoration: const InputDecoration(labelText: 'Multiplier'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(labelText: 'Priority (higher = first)'),
                  keyboardType: TextInputType.number,
                ),
                CheckboxListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) => setDialogState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.put('/loyalty/rules/${rule['id']}', {
                    'name': nameController.text,
                    'base_points_per_kes': double.tryParse(basePointsController.text) ?? 0.01,
                    'multiplier': double.tryParse(multiplierController.text) ?? 1.0,
                    'priority': int.tryParse(priorityController.text) ?? 0,
                    'is_active': isActive,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateRewardDialog() async {
    final nameController = TextEditingController();
    final pointsController = TextEditingController();
    final minTierController = TextEditingController(text: 'bronze');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Reward'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Reward Name'),
              ),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(labelText: 'Points Required'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: minTierController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Tier (bronze/silver/gold/platinum)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.post('/loyalty/rewards', {
                  'name': nameController.text,
                  'points_required': int.tryParse(pointsController.text) ?? 0,
                  'min_tier': minTierController.text.toLowerCase(),
                  'is_active': true,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRewardDialog(Map<String, dynamic> reward) async {
    final nameController = TextEditingController(text: reward['name']?.toString() ?? '');
    final pointsController = TextEditingController(
      text: (reward['points_required'] ?? reward['points_cost'] ?? 0).toString(),
    );
    final minTierController = TextEditingController(
      text: (reward['min_tier'] ?? reward['min_tier_required'] ?? 'bronze').toString(),
    );
    bool isActive = reward['is_active'] == true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Reward'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Reward Name'),
                ),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(labelText: 'Points Required'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: minTierController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Tier (bronze/silver/gold/platinum)',
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) => setDialogState(() {
                    isActive = value ?? false;
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.put('/loyalty/rewards/${reward['id']}', {
                    'name': nameController.text,
                    'points_cost': int.tryParse(pointsController.text) ?? reward['points_cost'] ?? 0,
                    'min_tier_required': minTierController.text.toLowerCase(),
                    'is_active': isActive,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProviderDetails(Map<String, dynamic> provider) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provider Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Provider ID: ${provider['provider_id']}'),
              const SizedBox(height: 8),
              Text('Tier: ${provider['participation_tier'] ?? 'N/A'}'),
              Text('Multiplier: ${provider['point_multiplier'] ?? 1.0}x'),
              Text('Billing Plan: ${provider['billing_plan'] ?? 'N/A'}'),
              Text('Points This Month: ${provider['points_awarded_this_month'] ?? 0}'),
              if (provider['monthly_point_budget'] != null)
                Text('Monthly Budget: ${provider['monthly_point_budget']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============ Actions ============
  Future<void> _deleteRule(String ruleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: const Text('Are you sure you want to delete this rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Note: Need DELETE endpoint in backend
        await ApiService.delete('/loyalty/rules/$ruleId');
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting rule: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleRule(String ruleId, bool activate) async {
    try {
      // Note: Need PUT/PATCH endpoint to update rule
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toggle rule - implement PUT endpoint')),
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteReward(String rewardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reward'),
        content: const Text('Are you sure you want to delete this reward?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/loyalty/rewards/$rewardId');
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting reward: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleReward(String rewardId, bool activate) async {
    try {
      await ApiService.put('/loyalty/rewards/$rewardId', {
        'is_active': activate,
      });
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

