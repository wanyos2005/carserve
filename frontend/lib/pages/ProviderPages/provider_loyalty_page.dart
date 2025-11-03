import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/loyalty_service.dart';

class ProviderLoyaltyPage extends StatefulWidget {
  final String providerId;

  const ProviderLoyaltyPage({super.key, required this.providerId});

  @override
  State<ProviderLoyaltyPage> createState() => _ProviderLoyaltyPageState();
}

class _ProviderLoyaltyPageState extends State<ProviderLoyaltyPage> {
  Map<String, dynamic>? _config;
  Map<String, dynamic>? _usage;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final config = await LoyaltyService.getProviderConfig(widget.providerId);
      final usage = await LoyaltyService.getProviderUsage(widget.providerId);
      setState(() {
        _config = config;
        _usage = usage;
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

  Future<void> _handleOptIn() async {
    final tier = await _showTierSelectionDialog();
    if (tier == null) return;

    final billingPlan = await _showBillingPlanDialog();
    if (billingPlan == null) return;

    Map<String, dynamic> billingParams = {};
    
    if (billingPlan == 'monthly_subscription') {
      final fee = await _showSubscriptionFeeDialog();
      if (fee == null) return;
      billingParams['monthlySubscriptionFee'] = fee;
    } else if (billingPlan == 'pay_per_point') {
      final rate = await _showRatePerPointDialog();
      if (rate == null) return;
      billingParams['billingRatePerPoint'] = rate;
    }

    final budget = await _showBudgetDialog();
    if (budget != null) {
      billingParams['monthlyPointBudget'] = budget;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await LoyaltyService.enableProvider(
        providerId: widget.providerId,
        participationTier: tier,
        billingPlan: billingPlan,
        monthlySubscriptionFee: billingParams['monthlySubscriptionFee'] as int?,
        billingRatePerPoint: billingParams['billingRatePerPoint'] as double?,
        monthlyPointBudget: billingParams['monthlyPointBudget'] as int?,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully opted into loyalty program!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opting in: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleOptOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opt Out of Loyalty Program'),
        content: const Text(
          'Are you sure you want to opt out? Customers will no longer earn points for your services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Opt Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final result = await LoyaltyService.disableProvider(widget.providerId);
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully opted out of loyalty program')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opting out: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showTierSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Participation Tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Basic'),
              subtitle: const Text('1.0x multiplier'),
              leading: const Icon(Icons.star_outline),
              onTap: () => Navigator.pop(context, 'basic'),
            ),
            ListTile(
              title: const Text('Premium'),
              subtitle: const Text('1.5x multiplier'),
              leading: const Icon(Icons.star, color: Colors.amber),
              onTap: () => Navigator.pop(context, 'premium'),
            ),
            ListTile(
              title: const Text('Elite'),
              subtitle: const Text('2.0x multiplier'),
              leading: const Icon(Icons.star, color: Colors.purple),
              onTap: () => Navigator.pop(context, 'elite'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showBillingPlanDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Billing Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Monthly Subscription'),
              subtitle: const Text('Fixed monthly fee'),
              leading: const Icon(Icons.calendar_today),
              onTap: () => Navigator.pop(context, 'monthly_subscription'),
            ),
            ListTile(
              title: const Text('Pay Per Point'),
              subtitle: const Text('Pay per point awarded'),
              leading: const Icon(Icons.payment),
              onTap: () => Navigator.pop(context, 'pay_per_point'),
            ),
            ListTile(
              title: const Text('Free'),
              subtitle: const Text('Platform-funded (no cost)'),
              leading: const Icon(Icons.free_breakfast),
              onTap: () => Navigator.pop(context, 'free'),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _showSubscriptionFeeDialog() async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Subscription Fee'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Fee (KES)',
            hintText: 'e.g., 3000',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final fee = int.tryParse(controller.text);
              Navigator.pop(context, fee);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<double?> _showRatePerPointDialog() async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Per Point'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'KES per point',
            hintText: 'e.g., 0.01',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final rate = double.tryParse(controller.text);
              Navigator.pop(context, rate);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<int?> _showBudgetDialog() async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Point Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set a monthly limit on points awarded (optional)'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Budget (points)',
                hintText: 'e.g., 50000',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), // No budget
            child: const Text('No Limit'),
          ),
          TextButton(
            onPressed: () {
              final budget = int.tryParse(controller.text);
              Navigator.pop(context, budget);
            },
            child: const Text('Set Budget'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        _buildStatusCard(theme),
                        const SizedBox(height: 20),

                        // Participation Details
                        if (_config != null && _config!['is_participating'] == true)
                          ..._buildParticipationDetails(theme),

                        // Usage Statistics
                        if (_usage != null)
                          ..._buildUsageStats(theme),

                        const SizedBox(height: 20),

                        // Action Buttons
                        _buildActionButtons(theme),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final isParticipating = _config?['is_participating'] ?? false;
    final tier = _config?['participation_tier'] ?? 'none';
    final multiplier = _config?['point_multiplier'] ?? 1.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isParticipating ? Icons.check_circle : Icons.cancel,
                  color: isParticipating ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isParticipating ? 'Participating' : 'Not Participating',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isParticipating ? Colors.green : Colors.grey,
                        ),
                      ),
                      if (isParticipating && tier != 'none')
                        Text(
                          '${tier.toString().toUpperCase()} Tier - ${multiplier}x multiplier',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
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
    );
  }

  List<Widget> _buildParticipationDetails(ThemeData theme) {
    return [
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participation Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Tier', _config?['participation_tier'] ?? 'N/A'),
              _buildDetailRow('Multiplier', '${_config?['point_multiplier'] ?? 1.0}x'),
              _buildDetailRow('Billing Plan', _config?['billing_plan'] ?? 'N/A'),
              if (_config?['monthly_subscription_fee'] != null)
                _buildDetailRow('Monthly Fee', 'KES ${_config?['monthly_subscription_fee']}'),
              if (_config?['billing_rate_per_point'] != null)
                _buildDetailRow('Rate Per Point', 'KES ${_config?['billing_rate_per_point']}'),
              if (_config?['monthly_point_budget'] != null)
                _buildDetailRow('Monthly Budget', '${_config?['monthly_point_budget']} points'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildUsageStats(ThemeData theme) {
    final pointsAwarded = _usage?['points_awarded_this_month'] ?? 0;
    final budget = _usage?['monthly_point_budget'];
    final pointsRemaining = budget != null ? (budget - pointsAwarded) : null;
    final usagePercent = budget != null ? (pointsAwarded / budget * 100) : null;

    return [
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Usage Statistics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Points Awarded This Month', pointsAwarded.toString()),
              if (budget != null) ...[
                _buildDetailRow('Monthly Budget', '$budget points'),
                if (pointsRemaining != null)
                  _buildDetailRow(
                    'Points Remaining',
                    pointsRemaining >= 0 ? pointsRemaining.toString() : 'Budget exceeded',
                  ),
                if (usagePercent != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: usagePercent / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usagePercent > 90 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${usagePercent.toStringAsFixed(1)}% of budget used',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
              if (_usage?['estimated_monthly_cost'] != null)
                _buildDetailRow(
                  'Estimated Monthly Cost',
                  'KES ${_usage?['estimated_monthly_cost']}',
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final isParticipating = _config?['is_participating'] ?? false;

    return Column(
      children: [
        if (!isParticipating)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleOptIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Opt In to Loyalty Program',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleOptOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Opt Out of Loyalty Program',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        const SizedBox(height: 12),
        // Sponsor Reward CTA
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _showSponsorRewardDialog,
            icon: const Icon(Icons.campaign),
            label: const Text('Sponsor a Reward'),
          ),
        ),
      ],
    );
  }

  Future<void> _showSponsorRewardDialog() async {
    final nameController = TextEditingController();
    final pointsController = TextEditingController();
    final valueController = TextEditingController();
    final voucherTemplateController = TextEditingController();
    final totalAvailableController = TextEditingController();
    final minTierController = TextEditingController(text: 'bronze');
    final coFundPctController = TextEditingController();
    String rewardType = 'voucher';
    String fundingModel = 'provider';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Sponsor a Reward'),
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
                  decoration: const InputDecoration(labelText: 'Points Cost'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: rewardType,
                  decoration: const InputDecoration(labelText: 'Reward Type'),
                  items: const [
                    DropdownMenuItem(value: 'voucher', child: Text('Voucher')),
                    DropdownMenuItem(value: 'discount', child: Text('Discount')),
                    DropdownMenuItem(value: 'cashback', child: Text('Cashback')),
                  ],
                  onChanged: (v) => setStateDialog(() => rewardType = v ?? 'voucher'),
                ),
                if (rewardType == 'voucher')
                  TextField(
                    controller: voucherTemplateController,
                    decoration: const InputDecoration(labelText: 'Voucher Code Template (e.g., FUEL10)'),
                  ),
                if (rewardType == 'discount')
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(labelText: 'Discount Amount (KES) or %'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                if (rewardType == 'cashback')
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(labelText: 'Cashback Amount (KES)'),
                    keyboardType: TextInputType.number,
                  ),
                DropdownButtonFormField<String>(
                  value: fundingModel,
                  decoration: const InputDecoration(labelText: 'Funding Model'),
                  items: const [
                    DropdownMenuItem(value: 'provider', child: Text('Provider-funded')),
                    DropdownMenuItem(value: 'co_funded', child: Text('Co-funded')),
                  ],
                  onChanged: (v) => setStateDialog(() => fundingModel = v ?? 'provider'),
                ),
                if (fundingModel == 'co_funded')
                  TextField(
                    controller: coFundPctController,
                    decoration: const InputDecoration(labelText: 'Provider Share (%)'),
                    keyboardType: TextInputType.number,
                  ),
                TextField(
                  controller: totalAvailableController,
                  decoration: const InputDecoration(labelText: 'Total Available (optional)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: minTierController,
                  decoration: const InputDecoration(labelText: 'Minimum Tier (bronze/silver/gold/platinum)'),
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
                  final pointsCost = int.tryParse(pointsController.text) ?? 0;
                  final totalAvail = int.tryParse(totalAvailableController.text);
                  final coPct = int.tryParse(coFundPctController.text);
                  final res = await LoyaltyService.sponsorReward(
                    providerId: widget.providerId,
                    name: nameController.text,
                    rewardType: rewardType,
                    pointsCost: pointsCost,
                    fundingModel: fundingModel,
                    coFundSplitPct: coPct,
                    totalAvailable: totalAvail,
                    minTierRequired: minTierController.text.toLowerCase(),
                    voucherCodeTemplate: voucherTemplateController.text.isEmpty ? null : voucherTemplateController.text,
                    discountAmount: (rewardType == 'discount') ? int.tryParse(valueController.text) : null,
                    cashbackAmount: (rewardType == 'cashback') ? int.tryParse(valueController.text) : null,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proposal submitted for approval')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit Proposal'),
            ),
          ],
        ),
      ),
    );
  }
}

