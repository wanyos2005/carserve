import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/loyalty_service.dart';
import 'package:flutter/services.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/services/api_service.dart';

class UserLoyaltyPage extends StatefulWidget {
  const UserLoyaltyPage({super.key});

  @override
  State<UserLoyaltyPage> createState() => _UserLoyaltyPageState();
}

class _UserLoyaltyPageState extends State<UserLoyaltyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Map<String, dynamic>? _account;
  List<dynamic> _transactions = [];
  List<dynamic> _rewards = [];
  bool _isLoading = true;

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
      final userId = UserContextService.currentContext?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final account = await LoyaltyService.getUserAccount(int.parse(userId));
      final transactions = await LoyaltyService.getUserTransactions(int.parse(userId));
      final rewards = await ApiService.get('/loyalty/rewards?is_active=true');
      
      setState(() {
        _account = account;
        _transactions = transactions;
        _rewards = rewards is List ? rewards : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading loyalty data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_circle), text: 'Account'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Rewards'),
          ],
        ),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAccountTab(theme),
                    _buildHistoryTab(theme),
                    _buildRewardsTab(theme),
                  ],
                ),
              ),
      ),
    );
  }

  // ============ Account Tab ============
  Widget _buildAccountTab(ThemeData theme) {
    if (_account == null) {
      return const Center(child: Text('No account found'));
    }

    final points = _account!['points_balance'] ?? 0;
    final tier = _account!['tier'] ?? 'bronze';
    final lifetimeEarned = _account!['lifetime_points_earned'] ?? 0;
    final lifetimeSpent = _account!['lifetime_points_spent'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Balance Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple[400]!,
                    Colors.blue[400]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Points',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    points.toString(),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tier Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getTierIcon(tier), color: _getTierColor(tier), size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Tier',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              tier.toUpperCase(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getTierColor(tier),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTierProgressBar(theme, tier, points),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Lifetime Points Earned', lifetimeEarned.toString()),
                  _buildStatRow('Lifetime Points Spent', lifetimeSpent.toString()),
                  _buildStatRow('Current Balance', points.toString()),
                ],
              ),
            ),
          ),

          // Tier Info
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tier Benefits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildTierBenefits(tier, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressBar(ThemeData theme, String tier, int points) {
    final tierThresholds = {
      'bronze': 0,
      'silver': 1000,
      'gold': 5000,
      'platinum': 20000,
    };
    
    final currentThreshold = tierThresholds[tier] ?? 0;
    final nextTier = _getNextTier(tier);
    final nextThreshold = tierThresholds[nextTier] ?? 0;
    
    int progress = 0;
    if (nextThreshold > currentThreshold) {
      progress = ((points - currentThreshold) / (nextThreshold - currentThreshold) * 100).round().clamp(0, 100);
    } else {
      progress = 100; // Max tier
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress to ${nextTier.toUpperCase()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              '$progress%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getTierColor(tier)),
        ),
        if (nextTier != tier)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${nextThreshold - points} points to next tier',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildTierBenefits(String tier, ThemeData theme) {
    final benefits = {
      'bronze': ['1.0x points multiplier', 'Access to basic rewards'],
      'silver': ['1.5x points multiplier', 'Access to silver-tier rewards'],
      'gold': ['2.0x points multiplier', 'Access to gold-tier rewards', 'Exclusive rewards'],
      'platinum': ['2.5x points multiplier', 'Access to all rewards', 'VIP support', 'Priority access'],
    };

    return (benefits[tier] ?? []).map((benefit) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(benefit, style: theme.textTheme.bodyMedium),
        ],
      ),
    )).toList();
  }

  String _getNextTier(String tier) {
    switch (tier) {
      case 'bronze': return 'silver';
      case 'silver': return 'gold';
      case 'gold': return 'platinum';
      default: return tier;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'bronze': return Icons.emoji_events;
      case 'silver': return Icons.workspace_premium;
      case 'gold': return Icons.star;
      case 'platinum': return Icons.diamond;
      default: return Icons.emoji_events;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'bronze': return Colors.brown;
      case 'silver': return Colors.grey;
      case 'gold': return Colors.amber;
      case 'platinum': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ============ History Tab ============
  Widget _buildHistoryTab(ThemeData theme) {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No transaction history',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isEarned = transaction['transaction_type'] == 'earned';
        final points = transaction['points_delta'] ?? 0;
        final date = transaction['created_at'];
        final extra = transaction['extra_metadata'];
        final voucherCode = (extra is Map) ? extra['voucher_code'] : null;

         return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEarned ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isEarned ? Icons.add : Icons.remove,
                color: isEarned ? Colors.green : Colors.red,
              ),
            ),
            title: Text(transaction['transaction_reason'] ?? 'Transaction'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date != null ? _formatDate(date) : 'Unknown date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (!isEarned && voucherCode != null && voucherCode is String && voucherCode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.confirmation_number, size: 16, color: Colors.purple),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SelectableText(
                            'Voucher: $voucherCode',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: voucherCode));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Voucher code copied')),
                              );
                            }
                          },
                          child: const Text('Copy', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Text(
              '${isEarned ? '+' : ''}$points',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isEarned ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  // ============ Rewards Tab ============
  Widget _buildRewardsTab(ThemeData theme) {
    if (_rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No rewards available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final availableRewards = _rewards.where((r) => r['is_active'] == true).toList();

    if (availableRewards.isEmpty) {
      return const Center(child: Text('No active rewards available'));
    }

    final userPoints = _account?['points_balance'] ?? 0;
    final userTier = _account?['tier'] ?? 'bronze';

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableRewards.length,
      itemBuilder: (context, index) {
        final reward = availableRewards[index];
        final pointsRequired = reward['points_cost'] ?? reward['points_required'] ?? 0;
        final minTier = reward['min_tier_required'] ?? reward['min_tier'] ?? 'bronze';
        final canRedeem = userPoints >= pointsRequired && _canAccessTier(userTier, minTier);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: canRedeem ? 4 : 2,
          child: ListTile(
            leading: Icon(
              Icons.card_giftcard,
              color: canRedeem ? Colors.purple : Colors.grey,
              size: 32,
            ),
            title: Text(reward['name'] ?? 'Reward'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pointsRequired} points required'),
                if (minTier != 'bronze')
                  Text(
                    'Min tier: ${minTier.toUpperCase()}',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: canRedeem
                  ? () => _redeemReward(reward)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Redeem'),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  bool _canAccessTier(String userTier, String requiredTier) {
    final tierOrder = ['bronze', 'silver', 'gold', 'platinum'];
    return tierOrder.indexOf(userTier) >= tierOrder.indexOf(requiredTier);
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Reward'),
        content: Text('Redeem "${reward['name']}" for ${reward['points_cost'] ?? reward['points_required']} points?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userId = UserContextService.currentContext?.id;
        if (userId == null) return;

        final account = await LoyaltyService.getUserAccount(int.parse(userId));
        if (account == null) return;

        final result = await ApiService.post('/loyalty/redemptions', {
          'account_id': account['id'],
          'reward_id': reward['id'],
        });

        if (result != null && mounted) {
          final code = result['voucher_code'];
          if (code != null && code is String && code.isNotEmpty) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Voucher Code'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Present this code at the station. One-time use.'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reward redeemed successfully!')),
            );
          }
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error redeeming reward: $e')),
          );
        }
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        final dt = DateTime.parse(date);
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }
}

