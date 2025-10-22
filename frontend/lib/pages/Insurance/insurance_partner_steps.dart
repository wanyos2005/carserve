import 'package:flutter/material.dart';
import 'package:car_platform/models/onboarding_config.dart';

class InsurancePartnerSteps {
  static Widget buildCompanyInfoForm(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return _CompanyInfoFormStep(data: data, onUpdate: onUpdate);
  }

  static Widget buildCapabilitiesSelection(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Capabilities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'What services do you support?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCapabilityCard(
                  context,
                  'Quote Generation',
                  'Generate insurance quotes for customers',
                  Icons.calculate,
                  data.get<bool>('supports_quotes') ?? false,
                  (value) => onUpdate(data.updateData('supports_quotes', value)),
                ),
                const SizedBox(height: 12),
                _buildCapabilityCard(
                  context,
                  'Claims Processing',
                  'Process and manage insurance claims',
                  Icons.assignment,
                  data.get<bool>('supports_claims') ?? false,
                  (value) => onUpdate(data.updateData('supports_claims', value)),
                ),
                const SizedBox(height: 12),
                _buildCapabilityCard(
                  context,
                  'Data Feeds',
                  'Receive vehicle and service data updates',
                  Icons.data_usage,
                  data.get<bool>('supports_data_feeds') ?? false,
                  (value) => onUpdate(data.updateData('supports_data_feeds', value)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildCapabilityCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    bool isSelected,
    Function(bool) onChanged,
  ) {
    return Card(
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(description),
        value: isSelected,
        onChanged: (value) => onChanged(value ?? false),
        activeColor: Colors.red,
        secondary: Icon(icon, color: isSelected ? Colors.red : Colors.grey),
      ),
    );
  }

  static Widget buildCoverageTypesSelection(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    final coverageTypes = [
      'comprehensive',
      'third_party',
      'fire_theft',
      'motor_commercial',
    ];

    final selectedTypes = data.get<List<String>>('supported_coverage_types') ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coverage Types',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'What types of insurance do you offer?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: ListView.separated(
            itemCount: coverageTypes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final type = coverageTypes[index];
              final isSelected = selectedTypes.contains(type);
              
              return Card(
                child: CheckboxListTile(
                  title: Text(
                    _getCoverageTypeDisplayName(type),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(_getCoverageTypeDescription(type)),
                  value: isSelected,
                  onChanged: (value) {
                    final newTypes = List<String>.from(selectedTypes);
                    if (value == true) {
                      newTypes.add(type);
                    } else {
                      newTypes.remove(type);
                    }
                    onUpdate(data.updateData('supported_coverage_types', newTypes));
                  },
                  activeColor: Colors.red,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _getCoverageTypeDisplayName(String type) {
    switch (type) {
      case 'comprehensive':
        return 'Comprehensive Insurance';
      case 'third_party':
        return 'Third Party Insurance';
      case 'fire_theft':
        return 'Fire & Theft Insurance';
      case 'motor_commercial':
        return 'Commercial Motor Insurance';
      default:
        return type;
    }
  }

  static String _getCoverageTypeDescription(String type) {
    switch (type) {
      case 'comprehensive':
        return 'Full coverage including own damage and third party';
      case 'third_party':
        return 'Covers damage to third party vehicles and property';
      case 'fire_theft':
        return 'Covers fire damage and theft of the vehicle';
      case 'motor_commercial':
        return 'Insurance for commercial vehicles and fleets';
      default:
        return 'Insurance coverage type';
    }
  }

  static Widget buildEnhancedInfoForm(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enhanced Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Add details that help customers choose you (Optional)',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Customer Rating
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Customer Rating (1.0 - 5.0)',
                    hintText: '4.5',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.star),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final rating = double.tryParse(value);
                    if (rating != null) onUpdate(data.updateData('customer_rating', rating));
                  },
                ),
                const SizedBox(height: 16),
                
                // Total Reviews
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Total Reviews',
                    hintText: '1250',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.rate_review),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final reviews = int.tryParse(value);
                    if (reviews != null) onUpdate(data.updateData('total_reviews', reviews));
                  },
                ),
                const SizedBox(height: 16),
                
                // Claims Processing Time
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Claims Processing Time',
                    hintText: '24-48 hours',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.speed),
                  ),
                  onChanged: (value) => onUpdate(data.updateData('claims_processing_time', value)),
                ),
                const SizedBox(height: 16),
                
                // Market Share
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Market Share',
                    hintText: '15%',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pie_chart),
                  ),
                  onChanged: (value) => onUpdate(data.updateData('market_share', value)),
                ),
                const SizedBox(height: 16),
                
                // Established Year
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Established Year',
                    hintText: '1985',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final year = int.tryParse(value);
                    if (year != null) onUpdate(data.updateData('established_year', year));
                  },
                ),
                const SizedBox(height: 16),
                
                // Website URL
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Website URL',
                    hintText: 'https://www.yourcompany.co.ke',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.language),
                  ),
                  onChanged: (value) => onUpdate(data.updateData('website_url', value)),
                ),
                const SizedBox(height: 16),
                
                // Logo URL
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Logo URL',
                    hintText: 'https://cdn.yourcompany.co.ke/logo.png',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image),
                  ),
                  onChanged: (value) => onUpdate(data.updateData('logo_url', value)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildApiConfigForm(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return _ApiConfigFormStep(data: data, onUpdate: onUpdate);
  }
}

class _CompanyInfoFormStep extends StatefulWidget {
  final OnboardingData data;
  final Function(OnboardingData) onUpdate;
  const _CompanyInfoFormStep({required this.data, required this.onUpdate});

  @override
  State<_CompanyInfoFormStep> createState() => _CompanyInfoFormStepState();
}

class _CompanyInfoFormStepState extends State<_CompanyInfoFormStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data.get<String>('name') ?? '');
    _codeController = TextEditingController(text: widget.data.get<String>('code') ?? '');
    _descriptionController = TextEditingController(text: widget.data.get<String>('description') ?? '');
    _emailController = TextEditingController(text: widget.data.get<String>('contact_email') ?? '');
    _phoneController = TextEditingController(text: widget.data.get<String>('contact_phone') ?? '');
    _addressController = TextEditingController(text: widget.data.get<String>('address') ?? '');
    for (final c in [_nameController, _codeController, _descriptionController, _emailController, _phoneController, _addressController]) {
      c.addListener(_syncBack);
    }
  }

  void _syncBack() {
    final updated = widget.data
        .updateData('name', _nameController.text)
        .updateData('code', _codeController.text)
        .updateData('description', _descriptionController.text)
        .updateData('contact_email', _emailController.text)
        .updateData('contact_phone', _phoneController.text)
        .updateData('address', _addressController.text);
    widget.onUpdate(updated);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Tell us about your insurance company',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name *',
                      hintText: 'e.g., Kenya Insurance Company',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Company Code *',
                      hintText: 'e.g., KIC',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Company Description *',
                      hintText: 'Describe your insurance services and expertise',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Email *',
                      hintText: 'partnerships@yourcompany.co.ke',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Required';
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                      return ok ? null : 'Invalid email';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                      hintText: '+254 20 123 4567',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Required';
                      final ok = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4}$').hasMatch(value);
                      return ok ? null : 'Invalid phone number';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Company Address',
                      hintText: 'e.g., Insurance House, Westlands, Nairobi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ApiConfigFormStep extends StatefulWidget {
  final OnboardingData data;
  final Function(OnboardingData) onUpdate;
  const _ApiConfigFormStep({required this.data, required this.onUpdate});

  @override
  State<_ApiConfigFormStep> createState() => _ApiConfigFormStepState();
}

class _ApiConfigFormStepState extends State<_ApiConfigFormStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiController;
  late final TextEditingController _webhookController;
  late final TextEditingController _commissionController;

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(text: widget.data.get<String>('api_endpoint') ?? '');
    _webhookController = TextEditingController(text: widget.data.get<String>('webhook_url') ?? '');
    _commissionController = TextEditingController(text: widget.data.get<int>('commission_rate')?.toString() ?? '');
    for (final c in [_apiController, _webhookController, _commissionController]) {
      c.addListener(_syncBack);
    }
  }

  void _syncBack() {
    var updated = widget.data
        .updateData('api_endpoint', _apiController.text)
        .updateData('webhook_url', _webhookController.text);
    final commission = int.tryParse(_commissionController.text);
    if (commission != null) {
      updated = updated.updateData('commission_rate', commission);
    }
    widget.onUpdate(updated);
  }

  @override
  void dispose() {
    _apiController.dispose();
    _webhookController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.api,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Configuration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Configure your API endpoints',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  TextFormField(
                    controller: _apiController,
                    decoration: const InputDecoration(
                      labelText: 'API Endpoint *',
                      hintText: 'https://api.yourcompany.co.ke',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _webhookController,
                    decoration: const InputDecoration(
                      labelText: 'Webhook URL',
                      hintText: 'https://api.yourcompany.co.ke/webhooks',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.webhook),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commissionController,
                    decoration: const InputDecoration(
                      labelText: 'Commission Rate (%)',
                      hintText: '10',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//so we have two classes here: _CompanyInfoFormStep and _ApiConfigFormStep
//the _CompanyInfoFormStep is used to collect the company information
//the _ApiConfigFormStep is used to collect the API configuration
//both of these classes are used to collect the data from the user
//the data is then used to create a new insurance partner
//the data is also used to update the existing insurance partner
//the data is also used to delete the existing insurance partner
//the data is also used to get the existing insurance partner

//they are both nested inside the InsurancePartnerSteps class, when rendering the insurance partner steps, we have two widgets that are rendered: buildCompanyInfoForm and buildApiConfigForm
//these widgets are then used to render the company information and API configuration forms

//the company information form is used to collect the company information
//the API configuration form is used to collect the API configuration
//both of these forms are used to collect the data from the user
//the data is then used to create a new insurance partner
//the data is also used to update the existing insurance partner
//the data is also used to delete the existing insurance partner
//the data is also used to get the existing insurance partner

//this file is imported by other files in this project like onboarding_config.dart. 
//the file that renders