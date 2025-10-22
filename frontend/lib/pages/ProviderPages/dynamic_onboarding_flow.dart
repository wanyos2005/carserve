import 'package:flutter/material.dart';

//import this to help us configure the onboarding flow for different types of businesses
import 'package:car_platform/models/onboarding_config.dart';
import 'package:car_platform/services/insurance_service.dart';
import 'package:car_platform/services/provider_service.dart';

class DynamicOnboardingFlow extends StatefulWidget {
  final OnboardingType type;

  const DynamicOnboardingFlow({
    super.key,
    required this.type,
  });

  @override
  State<DynamicOnboardingFlow> createState() => _DynamicOnboardingFlowState();
}

class _DynamicOnboardingFlowState extends State<DynamicOnboardingFlow> {
  late OnboardingConfig _config;
  late OnboardingData _data;
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _config = _getConfigForType(widget.type);
    _data = OnboardingData(type: widget.type);
  }

  OnboardingConfig _getConfigForType(OnboardingType type) {
    switch (type) {
      case OnboardingType.serviceProvider:
        return OnboardingConfigs.getServiceProviderConfig();
      case OnboardingType.insurancePartner:
        return OnboardingConfigs.getInsurancePartnerConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_config.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 30),
              
              // Step content
              Expanded(
                child: _buildCurrentStep(),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_config.steps.length, (index) {
        final isActive = _currentStep >= index;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < _config.steps.length - 1 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? _config.primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep >= _config.steps.length) {
      return _buildCompletionStep();
    }

    final step = _config.steps[_currentStep];
    return step.builder(context, _data, _updateData);
  }

  Widget _buildCompletionStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: 80,
          color: _config.primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Registration Complete! 🎉',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _config.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your ${_config.type == OnboardingType.serviceProvider ? 'service provider' : 'insurance partner'} account has been created successfully.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep >= _config.steps.length;
    final bool canProceed = !isLastStep && _config.steps[_currentStep].validator(_data);

    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (
                    isLastStep
                        ? _finishOnboarding
                        : (canProceed ? _proceedToNext : null)
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _config.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isLastStep ? 'Finish' : (canProceed ? 'Continue' : 'Complete required fields'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        if (_currentStep > 0 && !isLastStep) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: _goBack,
            child: Text(
              'Back',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _updateData(OnboardingData newData) {
    setState(() {
      _data = newData;
    });
  }

  void _proceedToNext() {
    if (_currentStep < _config.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeRegistration();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pop();
  }

  void _completeRegistration() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_config.type == OnboardingType.serviceProvider) {
        await _completeServiceProviderRegistration();
      } else {
        await _completeInsurancePartnerRegistration();
      }
      
      setState(() {
        _currentStep = _config.steps.length; // Move to completion step
      });
    } catch (e) {
      _showErrorDialog('Registration Failed', 'Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeServiceProviderRegistration() async {
    final selectedCategory = _data.get<String>('selectedBackendCategory');
    final name = _data.get<String>('name');
    final description = _data.get<String>('description');
    final phone = _data.get<String>('phone');
    final email = _data.get<String>('email');
    final location = _data.get<String>('location');

    if (selectedCategory == null || name == null || description == null || phone == null || location == null) {
      throw Exception('Missing required provider fields');
    }

    // Get category ID from backend
    final categories = await ProviderService.getProviderCategories();
    final category = categories.firstWhere(
      (cat) => cat['name'] == selectedCategory,
      orElse: () => throw Exception('Category not found'),
    );

    // Get location data if available
    final locationData = _data.get<Map<String, dynamic>>('locationData');
    
    // Use legacy-compatible location format
    Map<String, dynamic> locationInfo;
    if (locationData != null) {
      // Use the enhanced location data from location picker
      locationInfo = Map<String, dynamic>.from(locationData);
    } else {
      // Fallback to basic location string
      locationInfo = {
        'name': 'Nairobi',
        'lat': -1.2921,
        'lng': 36.8219,
        'address': location,
        'latitude': -1.2921,
        'longitude': 36.8219,
        'area': 'Nairobi',
        'readable_name': 'Nairobi',
      };
    }
    
    // Create provider
    final providerData = {
      'category_id': category['id'],
      'name': name,
      'description': description,
      'location': locationInfo,  // This now includes both legacy and enhanced format
      'contact_info': {
        'phone': phone,
        'email': email,
      },
      'is_registered': true,
    };

    final result = await ProviderService.createProvider(providerData);

    if (result != null) {
      final providerId = result['id'] ?? result['provider_id'];
      final selectedServiceIds = (_data.get<List>('selectedServices') ?? []).cast<String>();
      final availableServices = _data.get<List>('availableServices') ?? [];
      final valuesByService = Map<String, dynamic>.from(_data.get<Map>('serviceValues') ?? {});

      if (selectedServiceIds.isNotEmpty && providerId != null) {
        final servicesToAttach = selectedServiceIds.map((serviceId) {
          final service = availableServices.firstWhere((s) => s['id'] == serviceId);
          final values = Map<String, dynamic>.from(valuesByService[serviceId] ?? {});

          // Parse pricing information
          final pricingInfo = _parsePricingFromValues(values, service);

          return {
            'service_id': serviceId,
            'display_name': service['name'],
            
            // Legacy price field (for backward compatibility)
            'price': pricingInfo['display_price'],
            
            // New structured pricing fields
            'min_price': pricingInfo['min_price'],
            'max_price': pricingInfo['max_price'],
            'price_type': pricingInfo['price_type'],
            'currency': pricingInfo['currency'],
            'unit': pricingInfo['unit'],
            'negotiable': pricingInfo['negotiable'],
            
            'duration': _getDefaultDuration(service['name'] ?? ''),
            'booking_required': _getDefaultBookingRequired(service['name'] ?? ''),
            'extra_data': _buildExtraData(values, service),
          };
        }).toList();

        await ProviderService.attachServicesToProvider(providerId, servicesToAttach);
      }
    } else {
      throw Exception('Failed to create provider');
    }
  }

  String _getDefaultDuration(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('oil change')) return '30-45 mins';
    if (lower.contains('tyre')) return '30 mins';
    if (lower.contains('battery')) return '20 mins';
    if (lower.contains('refuel')) return '5-10 mins';
    if (lower.contains('wash')) return '30-60 mins';
    if (lower.contains('inspection')) return '1-2 hours';
    if (lower.contains('tune-up')) return '2-3 hours';
    return '1 hour';
  }

  bool _getDefaultBookingRequired(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('refuel')) return false;
    if (lower.contains('wash')) return false;
    if (lower.contains('tyre pressure')) return false;
    return true;
  }

  Map<String, dynamic> _buildExtraData(Map<String, dynamic> values, dynamic service) {
    final extraData = <String, dynamic>{};
    for (final key in values.keys) {
      if (key != 'price' && key != 'min_price' && key != 'max_price' && 
          key != 'price_type' && key != 'unit' && key != 'negotiable') {
        extraData[key] = values[key];
      }
    }
    extraData['service_category'] = service['category_name'];
    extraData['requirements_met'] = true;
    return extraData;
  }

  /// Parse pricing information from onboarding values
  Map<String, dynamic> _parsePricingFromValues(Map<String, dynamic> values, dynamic service) {
    // Check if we have structured pricing data from enhanced pricing form
    if (values.containsKey('price_type')) {
      final minPrice = values['min_price']?.toDouble();
      final maxPrice = values['max_price']?.toDouble();
      final priceType = values['price_type'] ?? 'range';
      final unit = values['unit'];
      final negotiable = values['negotiable'] ?? true;
      final currency = values['currency'] ?? 'KES';
      
      // Generate display price based on structured data
      String displayPrice;
      if (priceType == 'fixed' && minPrice != null) {
        displayPrice = '$currency ${minPrice.toStringAsFixed(0)}';
      } else if (priceType == 'range' && minPrice != null && maxPrice != null) {
        displayPrice = '$currency ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)}';
      } else if (priceType == 'per_unit' && minPrice != null && unit != null) {
        final unitText = unit == 'per_liter' ? '/liter' : 
                        unit == 'per_hour' ? '/hour' : 
                        unit == 'per_km' ? '/km' : '/unit';
        displayPrice = '$currency ${minPrice.toStringAsFixed(0)}$unitText';
      } else if (priceType == 'free') {
        displayPrice = 'Free';
      } else if (priceType == 'variable') {
        displayPrice = 'Contact for pricing';
      } else {
        displayPrice = 'Contact for pricing';
      }
      
      return {
        'display_price': displayPrice,
        'min_price': minPrice,
        'max_price': maxPrice,
        'price_type': priceType,
        'currency': currency,
        'unit': unit,
        'negotiable': negotiable,
      };
    }
    
    // Fall back to legacy price string parsing
    final priceString = values['price']?.toString() ?? 'Contact for pricing';
    return _parseLegacyPriceString(priceString);
  }

  /// Parse legacy price string format (e.g., "KSh 3,500 - 8,000", "KSh 1,500", "Free")
  Map<String, dynamic> _parseLegacyPriceString(String priceString) {
    if (priceString.isEmpty || priceString == 'Contact for pricing') {
      return {
        'display_price': 'Contact for pricing',
        'min_price': null,
        'max_price': null,
        'price_type': 'variable',
        'currency': 'KES',
        'unit': null,
        'negotiable': true,
      };
    }
    
    final lowerPrice = priceString.toLowerCase().trim();
    
    // Handle free services
    if (lowerPrice == 'free') {
      return {
        'display_price': 'Free',
        'min_price': 0.0,
        'max_price': 0.0,
        'price_type': 'free',
        'currency': 'KES',
        'unit': null,
        'negotiable': false,
      };
    }
    
    // Handle variable pricing
    if (lowerPrice.contains('varies') || lowerPrice.contains('contact')) {
      return {
        'display_price': 'Contact for pricing',
        'min_price': null,
        'max_price': null,
        'price_type': 'variable',
        'currency': 'KES',
        'unit': null,
        'negotiable': true,
      };
    }
    
    // Extract numbers from price string
    final regex = RegExp(r'[\d,]+');
    final matches = regex.allMatches(priceString);
    final numbers = matches.map((m) => double.tryParse(m.group(0)?.replaceAll(',', '') ?? '0') ?? 0.0).toList();
    
    // Determine unit
    String? unit;
    if (lowerPrice.contains('/liter')) {
      unit = 'per_liter';
    } else if (lowerPrice.contains('/hour')) {
      unit = 'per_hour';
    }
    
    if (numbers.isEmpty) {
      return {
        'display_price': 'Contact for pricing',
        'min_price': null,
        'max_price': null,
        'price_type': 'variable',
        'currency': 'KES',
        'unit': unit,
        'negotiable': true,
      };
    }
    
    if (numbers.length == 1) {
      return {
        'display_price': priceString,
        'min_price': numbers[0],
        'max_price': numbers[0],
        'price_type': unit != null ? 'per_unit' : 'fixed',
        'currency': 'KES',
        'unit': unit,
        'negotiable': true,
      };
    }
    
    if (numbers.length >= 2) {
      final minPrice = numbers.reduce((a, b) => a < b ? a : b);
      final maxPrice = numbers.reduce((a, b) => a > b ? a : b);
      return {
        'display_price': priceString,
        'min_price': minPrice,
        'max_price': maxPrice,
        'price_type': unit != null ? 'per_unit' : 'range',
        'currency': 'KES',
        'unit': unit,
        'negotiable': true,
      };
    }
    
    return {
      'display_price': 'Contact for pricing',
      'min_price': null,
      'max_price': null,
      'price_type': 'variable',
      'currency': 'KES',
      'unit': null,
      'negotiable': true,
    };
  }

  Future<void> _completeInsurancePartnerRegistration() async {
    final partnerData = {
      'name': _data.get<String>('name') ?? '',
      'code': _data.get<String>('code') ?? '',
      'api_endpoint': _data.get<String>('api_endpoint') ?? '',
      'webhook_url': _data.get<String>('webhook_url') ?? '',
      'supports_quotes': _data.get<bool>('supports_quotes') ?? false,
      'supports_claims': _data.get<bool>('supports_claims') ?? false,
      'supports_data_feeds': _data.get<bool>('supports_data_feeds') ?? false,
      'commission_rate': _data.get<int>('commission_rate'),
      'contact_info': {
        'email': _data.get<String>('contact_email') ?? '',
        'phone': _data.get<String>('contact_phone') ?? '',
        'address': _data.get<String>('address') ?? '',
      },
      'supported_coverage_types': _data.get<List<String>>('supported_coverage_types') ?? [],
      
      // Enhanced fields
      'customer_rating': _data.get<double>('customer_rating'),
      'total_reviews': _data.get<int>('total_reviews'),
      'claims_processing_time': _data.get<String>('claims_processing_time'),
      'policy_validity_period': _data.get<String>('policy_validity_period'),
      'special_features': _data.get<List<String>>('special_features') ?? [],
      'logo_url': _data.get<String>('logo_url'),
      'website_url': _data.get<String>('website_url'),
      'established_year': _data.get<int>('established_year'),
      'market_share': _data.get<String>('market_share'),
      'awards': _data.get<List<String>>('awards') ?? [],
    };

    // Remove null values
    partnerData.removeWhere((key, value) => value == null);
    
    final result = await InsuranceService.createPartner(partnerData);
    
    if (result == null) {
      throw Exception('Failed to create insurance partner');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
