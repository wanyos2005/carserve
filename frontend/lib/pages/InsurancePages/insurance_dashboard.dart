import 'package:flutter/material.dart';
import 'package:car_platform/services/insurance_service.dart';
import 'package:car_platform/models/insurance_models.dart';
import 'package:car_platform/services/user_context_service.dart';
import 'package:car_platform/pages/insurance_policy_page.dart';

class InsuranceDashboard extends StatefulWidget {
  const InsuranceDashboard({super.key});

  @override
  State<InsuranceDashboard> createState() => _InsuranceDashboardState();
}

class _InsuranceDashboardState extends State<InsuranceDashboard> {
  List<InsurancePolicy> _policies = [];
  List<InsuranceClaim> _claims = [];
  RiskScore? _riskScore;
  bool _isLoading = true;
  String? _error;
  bool _showAllPolicies = false;

  @override
  void initState() {
    super.initState();
    _loadInsuranceData();
  }

  Future<void> _loadInsuranceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userContext = UserContextService.currentContext;
      if (userContext == null || userContext.id == null) {
        throw Exception('User not logged in');
      }
      final userId = int.tryParse(userContext.id!);
      if (userId == null) {
        throw Exception('Invalid user ID');
      }

      // Load policies, claims, and risk score in parallel
      final results = await Future.wait([
        InsuranceService.getPolicies(userId: userId),
        InsuranceService.getClaims(userId: userId),
        // For now, we'll use a mock vehicle ID - in real app, get from user's vehicles
        InsuranceService.getRiskScore(vehicleId: 'mock-vehicle', userId: userId).catchError((e) => null),
      ]);

      setState(() {
        _policies = (results[0] as List<Map<String, dynamic>>)
            .map((json) => InsurancePolicy.fromJson(json))
            .toList();
        
        _claims = (results[1] as List<Map<String, dynamic>>)
            .map((json) => InsuranceClaim.fromJson(json))
            .toList();
        
        // Handle nullable risk score
        final riskScoreData = results[2] as Map<String, dynamic>?;
        if (riskScoreData != null && riskScoreData.isNotEmpty) {
          _riskScore = RiskScore.fromJson(riskScoreData);
        } else {
          _riskScore = null;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Dashboard'),
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsuranceData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildDashboard(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/insurance/marketplace');
        },
        icon: const Icon(Icons.search),
        label: const Text('Get Quotes'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading insurance data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadInsuranceData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadInsuranceData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRiskScoreCard(),
            const SizedBox(height: 16),
            _buildPoliciesSection(),
            const SizedBox(height: 16),
            _buildClaimsSection(),
            const SizedBox(height: 16),
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Risk Score',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_riskScore != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Combined Risk Score',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_riskScore!.combinedRiskScore ?? 0}/100',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _getRiskColor(_riskScore!.combinedRiskScore ?? 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _riskScore!.riskLevel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _getRiskColor(_riskScore!.combinedRiskScore ?? 0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildRiskScoreItem('Vehicle', _riskScore!.vehicleRiskScore ?? 0),
                      const SizedBox(height: 8),
                      _buildRiskScoreItem('Driver', _riskScore!.driverRiskScore ?? 0),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No risk score available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: Calculate risk score
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Risk score calculation coming soon!')),
                  );
                },
                child: const Text('Calculate Risk Score'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreItem(String label, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getRiskColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRiskColor(score).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            '$score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _getRiskColor(score),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.red;
    return Colors.red[800]!;
  }

  Widget _buildPoliciesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Insurance Policies',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/insurance/policies');
                      },
                      child: const Text('View All'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InsurancePolicyPage(),
                          ),
                        );
                      },
                      child: const Text('Add Policy Manually'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_policies.isEmpty)
          _buildEmptyState(
            icon: Icons.policy,
            title: 'No Insurance Policies',
            subtitle: 'Get quotes and purchase insurance for your vehicles',
            actionText: 'Get Quotes',
            onAction: () {
              Navigator.pushNamed(context, '/insurance/marketplace');
            },
          )
        else ...[
          _buildLatestPolicySummary(_policies.first),
          const SizedBox(height: 8),
          if (_showAllPolicies) ...[
            ..._policies.map((p) => _buildPolicyCard(p)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _showAllPolicies = false),
                child: const Text('Show Less'),
              ),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _showAllPolicies = true),
                child: const Text('View All'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLatestPolicySummary(InsurancePolicy policy) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.policy, color: _getPolicyStatusColor(policy.status)),
                const SizedBox(width: 8),
                Text(
                  'Latest Policy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildPolicyStatusChip(policy.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              runSpacing: 8,
              spacing: 16,
              children: [
                _buildInfoChip('Type', policy.insuranceType.toUpperCase()),
                if (policy.policyNumber != null) _buildInfoChip('Policy', policy.policyNumber!),
                if (policy.commencementDate != null) _buildInfoChip('Start', _formatDate(policy.commencementDate!)),
                if (policy.expiryDate != null) _buildInfoChip('Expires', _formatDate(policy.expiryDate!)),
                _buildInfoChip('Status', policy.status.toUpperCase()),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/insurance/policy-details',
                    arguments: policy.id,
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(InsurancePolicy policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPolicyStatusColor(policy.status),
          child: Icon(
            Icons.policy,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          policy.insuranceType.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (policy.policyNumber != null)
              Text('Policy: ${policy.policyNumber}'),
            if (policy.expiryDate != null)
              Text(
                'Expires: ${_formatDate(policy.expiryDate!)}',
                style: TextStyle(
                  color: policy.isExpiringSoon ? Colors.red : Colors.grey[600],
                  fontWeight: policy.isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            if (policy.premiumAmount != null)
              Text('Premium: KSh ${(policy.premiumAmount! / 100).toStringAsFixed(0)}'),
          ],
        ),
        trailing: _buildPolicyStatusChip(policy.status),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/insurance/policy-details',
            arguments: policy.id,
          );
        },
      ),
    );
  }

  Widget _buildPolicyStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'expired':
        color = Colors.red;
        break;
      case 'cancelled':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPolicyStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Widget _buildClaimsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Claims',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/insurance/claims');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_claims.isEmpty)
          _buildEmptyState(
            icon: Icons.assignment,
            title: 'No Claims',
            subtitle: 'You haven\'t filed any insurance claims yet',
            actionText: 'File Claim',
            onAction: () {
              Navigator.pushNamed(context, '/insurance/file-claim');
            },
          )
        else
          ...(_claims.take(3).map((claim) => _buildClaimCard(claim))),
      ],
    );
  }

  Widget _buildClaimCard(InsuranceClaim claim) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getClaimStatusColor(claim.status),
          child: Icon(
            Icons.assignment,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          claim.claimType.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (claim.claimNumber != null)
              Text('Claim: ${claim.claimNumber}'),
            if (claim.incidentDate != null)
              Text('Incident: ${_formatDate(claim.incidentDate!)}'),
            if (claim.estimatedCost != null)
              Text('Estimated: KSh ${(claim.estimatedCost! / 100).toStringAsFixed(0)}'),
          ],
        ),
        trailing: _buildClaimStatusChip(claim.status),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/insurance/claim-details',
            arguments: claim.id,
          );
        },
      ),
    );
  }

  Widget _buildClaimStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'submitted':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getClaimStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'submitted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.search,
                title: 'Get Quotes',
                subtitle: 'Compare insurance quotes',
                color: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, '/insurance/marketplace');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.assignment,
                title: 'File Claim',
                subtitle: 'Submit insurance claim',
                color: Colors.orange,
                onTap: () {
                  Navigator.pushNamed(context, '/insurance/file-claim');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.policy,
                title: 'My Policies',
                subtitle: 'Manage policies',
                color: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/insurance/policies');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.add_circle,
                title: 'Create Policy',
                subtitle: 'Manual entry',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InsurancePolicyPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics,
                title: 'Risk Score',
                subtitle: 'View risk analysis',
                color: Colors.purple,
                onTap: () {
                  Navigator.pushNamed(context, '/insurance/risk-analysis');
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

