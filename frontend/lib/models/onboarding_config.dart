//file used to configure the onboarding flow for different types of businesses
import 'package:flutter/material.dart';
import 'package:car_platform/pages/Insurance/insurance_partner_steps.dart';
import 'package:car_platform/pages/ProviderPages/provider_steps.dart';
import 'package:car_platform/components/location_picker.dart';

enum OnboardingType {
  serviceProvider,
  insurancePartner,
}

class OnboardingConfig {
  final OnboardingType type;
  final String title;
  final String description;
  final Color primaryColor;
  final IconData icon;
  final List<OnboardingStep> steps;
  final Map<String, dynamic> defaultData;

  const OnboardingConfig({
    required this.type,
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.icon,
    required this.steps,
    this.defaultData = const {},
  });
}

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final Widget Function(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) builder;
  final bool Function(OnboardingData data) validator;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.builder,
    required this.validator,
  });
}

class OnboardingData {
  final OnboardingType type;
  final Map<String, dynamic> data;

  const OnboardingData({
    required this.type,
    this.data = const {},
  });

  OnboardingData copyWith({
    OnboardingType? type,
    Map<String, dynamic>? data,
  }) {
    return OnboardingData(
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  OnboardingData updateData(String key, dynamic value) {
    final newData = Map<String, dynamic>.from(data);
    newData[key] = value;
    return copyWith(data: newData);
  }

  T? get<T>(String key) {
    return data[key] as T?;
  }

  bool has(String key) {
    return data.containsKey(key);
  }
}

class OnboardingConfigs {
  static OnboardingConfig getServiceProviderConfig() {
    return OnboardingConfig(
      type: OnboardingType.serviceProvider,
      title: 'Service Provider Registration',
      description: 'Join our network of trusted service providers',
      primaryColor: Colors.red,
      icon: Icons.build_circle,
      steps: [
        OnboardingStep(
          id: 'business_type',
          title: 'Business Type',
          description: 'What type of business do you run?',
          builder: ProviderSteps.buildBusinessTypeSelection,
          validator: (data) => data.has('selectedGroup'),
        ),
        OnboardingStep(
          id: 'category',
          title: 'Service Category',
          description: 'Which specific service do you provide?',
          builder: ProviderSteps.buildCategorySelection,
          validator: (data) => data.has('selectedBackendCategory'),
        ),
        OnboardingStep(
          id: 'details',
          title: 'Business Details',
          description: 'Tell us about your business',
          builder: ProviderSteps.buildProviderDetailsForm,
          validator: (data) {
            final name = (data.get<String>('name') ?? '').trim();
            final desc = (data.get<String>('description') ?? '').trim();
            final phone = (data.get<String>('phone') ?? '').trim();
            final location = (data.get<String>('location') ?? '').trim();
            return name.isNotEmpty && desc.isNotEmpty && phone.isNotEmpty && location.isNotEmpty;
          },
        ),
        OnboardingStep(
          id: 'location',
          title: 'Business Location',
          description: 'Pinpoint your exact business location',
          builder: _buildLocationStep,
          validator: (data) => data.has('locationData'),
        ),
        OnboardingStep(
          id: 'services',
          title: 'Select Services',
          description: 'Choose the services you offer',
          builder: ProviderSteps.buildServiceSelection,
          validator: (data) => data.has('selectedServices') && (data.get<List>('selectedServices')?.isNotEmpty ?? false),
        ),
      ],
    );
  }

  static OnboardingConfig getInsurancePartnerConfig() {
    return OnboardingConfig(
      type: OnboardingType.insurancePartner,
      title: 'Insurance Partner Registration',
      description: 'Join our insurance marketplace as a partner',
      primaryColor: Colors.red,
      icon: Icons.security,
      steps: [
        OnboardingStep(
          id: 'company_info',
          title: 'Company Information',
          description: 'Tell us about your insurance company',
          builder: _buildCompanyInfoForm,
          validator: (data) => 
            data.has('name') && 
            data.has('code') && 
            data.has('description') && 
            data.has('contact_email'),
        ),
        OnboardingStep(
          id: 'capabilities',
          title: 'Service Capabilities',
          description: 'What services do you support?',
          builder: _buildCapabilitiesSelection,
          validator: (data) => 
            data.has('supports_quotes') || 
            data.has('supports_claims') || 
            data.has('supports_data_feeds'),
        ),
        OnboardingStep(
          id: 'coverage_types',
          title: 'Coverage Types',
          description: 'What types of insurance do you offer?',
          builder: _buildCoverageTypesSelection,
          validator: (data) => data.has('supported_coverage_types') && (data.get<List>('supported_coverage_types')?.isNotEmpty ?? false),
        ),
        OnboardingStep(
          id: 'enhanced_info',
          title: 'Enhanced Information',
          description: 'Add details that help customers choose you',
          builder: _buildEnhancedInfoForm,
          validator: (data) => true, // Optional step
        ),
        OnboardingStep(
          id: 'api_config',
          title: 'API Configuration',
          description: 'Configure your API endpoints',
          builder: _buildApiConfigForm,
          validator: (data) => data.has('api_endpoint'),
        ),
      ],
    );
  }

  // Service Provider Step Builders are implemented in ProviderSteps

  // Insurance Partner Step Builders
  static Widget _buildCompanyInfoForm(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return InsurancePartnerSteps.buildCompanyInfoForm(context, data, onUpdate);
  }

  static Widget _buildCapabilitiesSelection(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return InsurancePartnerSteps.buildCapabilitiesSelection(context, data, onUpdate);
  }

  static Widget _buildCoverageTypesSelection(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return InsurancePartnerSteps.buildCoverageTypesSelection(context, data, onUpdate);
  }

  static Widget _buildEnhancedInfoForm(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return InsurancePartnerSteps.buildEnhancedInfoForm(context, data, onUpdate);
  }

  static Widget _buildApiConfigForm(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return InsurancePartnerSteps.buildApiConfigForm(context, data, onUpdate);
  }

  // Location step builder for service providers
  static Widget _buildLocationStep(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Business Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pinpoint your exact business location to help customers find you easily.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Location picker
          LocationPicker(
            label: "Your Business Location",
            hint: "Tap to select your workshop/garage location",
            onLocationSelected: (location) {
              onUpdate(data.updateData('locationData', location));
            },
            showCurrentLocationButton: true,
            required: true,
          ),
          
          const SizedBox(height: 24),
          
          // Information card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Why do we need your location?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "• Help customers find nearby service providers\n"
                    "• Calculate accurate distances for service delivery\n"
                    "• Show your business in location-based searches\n"
                    "• Enable route optimization for service calls",
                    style: TextStyle(
                      color: Colors.blue[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Service area information
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_searching, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Service Coverage Area",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your service area will be automatically set based on your location. "
                    "You can adjust this later in your provider dashboard.",
                    style: TextStyle(
                      color: Colors.green[600],
                      height: 1.5,
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
}

