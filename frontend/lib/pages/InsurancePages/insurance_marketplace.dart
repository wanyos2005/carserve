import 'package:flutter/material.dart';
import 'package:car_platform/services/insurance_service.dart';
import 'package:car_platform/models/insurance_models.dart';
import 'package:car_platform/services/user_context_service.dart';
import 'package:car_platform/services/vehicle_service.dart';

class InsuranceMarketplace extends StatefulWidget {
  const InsuranceMarketplace({super.key});

  @override
  State<InsuranceMarketplace> createState() => _InsuranceMarketplaceState();
}

class _InsuranceMarketplaceState extends State<InsuranceMarketplace> {
  final _formKey = GlobalKey<FormState>();
  final _coverageAmountController = TextEditingController();
  final _deductibleAmountController = TextEditingController();

  String _selectedCoverageType = 'comprehensive';
  List<InsuranceQuote> _quotes = [];
  List<InsurancePartner> _partners = [];
  List<dynamic> _vehicles = [];
  String? _selectedVehicleId;
  bool _isLoading = false;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _coverageAmountController.dispose();
    _deductibleAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _initialLoading = true);

    try {
      // Load vehicles and partners in parallel
      final futures = await Future.wait([
        VehicleService.listVehicles(),
        InsuranceService.getPartners(),
      ]);

      final vehicles = futures[0];
      final partnersData = futures[1];

      setState(() {
        _vehicles = vehicles;
        _partners = partnersData
            .map((json) => InsurancePartner.fromJson(json))
            .where((partner) => partner.isActive && partner.supportsQuotes)
            .toList();
        
        // Auto-select first vehicle if available
        if (_vehicles.isNotEmpty && _selectedVehicleId == null) {
          _selectedVehicleId = _vehicles.first["id"].toString();
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
      });
    } finally {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _getQuotes() async {
    if (!_formKey.currentState!.validate()) return;

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

      if (_selectedVehicleId == null) {
        throw Exception('Please select a vehicle');
      }

      final quotesData = await InsuranceService.getQuotes(
        vehicleId: _selectedVehicleId!,
        userId: userId,
        coverageType: _selectedCoverageType,
        //we need to multiply by 100 because the api expects the amount in cents, while in Kenya we use KSh, so in this case the currency is submitted in cents and not KSh, if we wanted 
        coverageAmount: _coverageAmountController.text.isNotEmpty
            ? int.parse(_coverageAmountController.text) * 100
            : null,
        deductibleAmount: _deductibleAmountController.text.isNotEmpty
            ? int.parse(_deductibleAmountController.text) * 100
            : null,
      );

      setState(() {
        if (quotesData != null && quotesData['quotes'] != null) {
          _quotes = (quotesData['quotes'] as List<dynamic>)
              .map((json) => InsuranceQuote.fromJson(json))
              .toList();
        } else {
          _quotes = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get quotes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Insurance Marketplace'),
          backgroundColor: Colors.red[500],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Marketplace'),
        backgroundColor: Colors.red[500],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuoteForm(),
            const SizedBox(height: 24),
            if (_quotes.isNotEmpty) _buildQuotesSection(),
            if (_error != null) _buildErrorSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get Insurance Quotes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                isExpanded: true,
                selectedItemBuilder: (context) {
                  return _vehicles.map<Widget>((v) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatVehicleDisplay(v),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList();
                },
                decoration: const InputDecoration(
                  labelText: 'Select Vehicle',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: _vehicles
                    .map((v) => DropdownMenuItem<String>(
                          value: v["id"].toString(),
                          child: Text(
                            _formatVehicleDisplay(v),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVehicleId = val),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a vehicle';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCoverageType,
                decoration: const InputDecoration(
                  labelText: 'Coverage Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'comprehensive',
                    child: Text('Comprehensive'),
                  ),
                  DropdownMenuItem(
                    value: 'third_party',
                    child: Text('Third Party'),
                  ),
                  DropdownMenuItem(
                    value: 'fire_theft',
                    child: Text('Fire & Theft'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCoverageType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coverageAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Coverage Amount (KSh)',
                        hintText: '1000000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final amount = int.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _deductibleAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Deductible (KSh)',
                        hintText: '10000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money_off),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final amount = int.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _getQuotes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Getting Quotes...'),
                          ],
                        )
                      : const Text('Get Quotes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Quotes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare quotes from ${_quotes.length} insurance partners',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ..._quotes.map((quote) => _buildQuoteCard(quote)),
      ],
    );
  }

  Widget _buildQuoteCard(InsuranceQuote quote) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    quote.partnerName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.partnerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Valid until ${_formatDate(quote.quoteValidUntil)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    quote.formattedPremium,
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuoteDetail(
                    'Coverage Type',
                    quote.coverageDetails['coverage_type']?.toString().toUpperCase() ?? 'N/A',
                    Icons.security,
                  ),
                ),
                Expanded(
                  child: _buildQuoteDetail(
                    'Coverage Amount',
                    'KSh ${(quote.coverageDetails['coverage_amount'] ?? 0) / 100}',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuoteDetail(
                    'Deductible',
                    quote.formattedDeductible,
                    Icons.money_off,
                  ),
                ),
                Expanded(
                  child: _buildQuoteDetail(
                    'Claims Processing',
                    _getPartnerClaimsTime(quote.partnerId),
                    Icons.speed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuoteDetail(
                    'Customer Rating',
                    _getPartnerRating(quote.partnerId),
                    Icons.star,
                  ),
                ),
                Expanded(
                  child: _buildQuoteDetail(
                    'Policy Period',
                    _getPartnerPolicyPeriod(quote.partnerId),
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            // Special Features Section
            if (_getPartnerSpecialFeatures(quote.partnerId).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Special Features',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: _getPartnerSpecialFeatures(quote.partnerId).take(3).map((feature) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[800],
                          ),
                        ),
                      )).toList()
                        ..addAll(_getPartnerSpecialFeatures(quote.partnerId).length > 3 ? [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "+${_getPartnerSpecialFeatures(quote.partnerId).length - 3} more",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ] : []),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showQuoteDetails(quote);
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _purchasePolicy(quote);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Purchase'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteDetail(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.red[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuoteDetails(InsuranceQuote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quote Details - ${quote.partnerName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Premium Amount', quote.formattedPremium),
              _buildDetailRow('Coverage Type', quote.coverageDetails['coverage_type']?.toString().toUpperCase() ?? 'N/A'),
              _buildDetailRow('Coverage Amount', 'KSh ${(quote.coverageDetails['coverage_amount'] ?? 0) / 100}'),
              _buildDetailRow('Deductible', quote.formattedDeductible),
              _buildDetailRow('Valid Until', _formatDate(quote.quoteValidUntil)),
              if (quote.termsAndConditions != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Terms & Conditions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quote.termsAndConditions!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _purchasePolicy(quote);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _purchasePolicy(InsuranceQuote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Policy'),
        content: Text(
          'Are you sure you want to purchase this policy from ${quote.partnerName} for ${quote.formattedPremium}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPurchase(quote);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Purchase'),
          ),
        ],
      ),
    );
  }

  void _processPurchase(InsuranceQuote quote) {
    // TODO: Implement actual policy purchase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Policy purchase from ${quote.partnerName} coming soon!'),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  int _getPartnerCommission(String partnerId) {
    final partner = _partners.firstWhere(
      (p) => p.id == partnerId,
      orElse: () => InsurancePartner(
        id: '',
        name: '',
        code: '',
        supportsQuotes: false,
        supportsClaims: false,
        supportsDataFeeds: false,
        isActive: false,
      ),
    );
    return partner.commissionRate ?? 0;
  }

  String _getPartnerClaimsTime(String partnerId) {
    final partner = _partners.firstWhere(
      (p) => p.id == partnerId,
      orElse: () => InsurancePartner(
        id: '',
        name: '',
        code: '',
        supportsQuotes: false,
        supportsClaims: false,
        supportsDataFeeds: false,
        isActive: false,
      ),
    );
    return partner.claimsProcessingTime ?? 'Not specified';
  }

  String _getPartnerRating(String partnerId) {
    final partner = _partners.firstWhere(
      (p) => p.id == partnerId,
      orElse: () => InsurancePartner(
        id: '',
        name: '',
        code: '',
        supportsQuotes: false,
        supportsClaims: false,
        supportsDataFeeds: false,
        isActive: false,
      ),
    );
    if (partner.customerRating != null && partner.totalReviews != null) {
      return '${partner.customerRating}/5.0 (${partner.totalReviews} reviews)';
    } else if (partner.customerRating != null) {
      return '${partner.customerRating}/5.0';
    }
    return 'No rating';
  }

  String _getPartnerPolicyPeriod(String partnerId) {
    final partner = _partners.firstWhere(
      (p) => p.id == partnerId,
      orElse: () => InsurancePartner(
        id: '',
        name: '',
        code: '',
        supportsQuotes: false,
        supportsClaims: false,
        supportsDataFeeds: false,
        isActive: false,
      ),
    );
    return partner.policyValidityPeriod ?? '12 months';
  }

  List<String> _getPartnerSpecialFeatures(String partnerId) {
    final partner = _partners.firstWhere(
      (p) => p.id == partnerId,
      orElse: () => InsurancePartner(
        id: '',
        name: '',
        code: '',
        supportsQuotes: false,
        supportsClaims: false,
        supportsDataFeeds: false,
        isActive: false,
      ),
    );
    return partner.specialFeatures ?? [];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatVehicleDisplay(Map<String, dynamic> vehicle) {
    final plate = vehicle["plate"]?.toString() ?? "";
    final make = vehicle["make"]?.toString() ?? "";
    final model = vehicle["model"]?.toString() ?? "";
    
    // Create a more compact display format
    if (plate.isNotEmpty && make.isNotEmpty && model.isNotEmpty) {
      return "$plate $make $model";
    } else if (plate.isNotEmpty && make.isNotEmpty) {
      return "$plate $make";
    } else if (plate.isNotEmpty) {
      return plate;
    } else if (make.isNotEmpty && model.isNotEmpty) {
      return "$make $model";
    } else {
      return "Vehicle ${vehicle["id"]}";
    }
  }
}
