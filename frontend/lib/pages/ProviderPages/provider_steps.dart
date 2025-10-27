import 'package:flutter/material.dart';


import 'package:driveon_car_platform/models/onboarding_config.dart'; //from this import we get the OnboardingData class
import 'package:driveon_car_platform/models/frontend_category_grouping.dart'; //from this import we get the FrontendCategoryGroup class
import 'package:driveon_car_platform/models/service_requirements_helper.dart'; //from this import we get the ServiceRequirementsHelper class
import 'package:driveon_car_platform/BookingPageHelpers/enhanced_service_selector.dart';
import 'package:driveon_car_platform/services/global_service_api.dart';

class ProviderSteps {
  static Widget buildBusinessTypeSelection(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    final groups = FrontendCategoryGroups.getAllGroups();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of business do you run?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the category that best describes your business',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              final isSelected = data.get<FrontendCategoryGroup>('selectedGroup')?.name == group.name;
              return GestureDetector(
                onTap: () => onUpdate(data.updateData('selectedGroup', group)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? group.color.withOpacity(0.08) : Colors.white,
                    border: Border.all(
                      color: isSelected ? group.color : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: group.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(group.icon, color: group.color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? group.color : null,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              group.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) Icon(Icons.check_circle, color: group.color),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget buildCategorySelection(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    final group = data.get<FrontendCategoryGroup>('selectedGroup');
    if (group == null) {
      return const Center(child: Text('Select a business type first'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: group.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(group.icon, color: group.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: group.color,
                        ),
                  ),
                  Text(
                    'Which specific service do you provide?',
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
            itemCount: group.backendCategories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = group.backendCategories[index];
              final isSelected = data.get<String>('selectedBackendCategory') == category;
              return GestureDetector(
                onTap: () => onUpdate(data.updateData('selectedBackendCategory', category)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? group.color.withOpacity(0.08) : Colors.white,
                    border: Border.all(
                      color: isSelected ? group.color : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? group.color : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? group.color : null,
                              ),
                        ),
                      ),
                      if (isSelected) Icon(Icons.check_circle, color: group.color),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget buildProviderDetailsForm(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return _ProviderDetailsStep(data: data, onUpdate: onUpdate);
  }

  static Widget buildServiceSelection(BuildContext context, OnboardingData data, Function(OnboardingData) onUpdate) {
    return _ProviderServiceSelectionStep(data: data, onUpdate: onUpdate);
  }
}

class _ProviderDetailsStep extends StatefulWidget {
  final OnboardingData data;
  final Function(OnboardingData) onUpdate;

  const _ProviderDetailsStep({required this.data, required this.onUpdate});

  @override
  State<_ProviderDetailsStep> createState() => _ProviderDetailsStepState();
}

class _ProviderDetailsStepState extends State<_ProviderDetailsStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data.get<String>('name') ?? '');
    _descriptionController = TextEditingController(text: widget.data.get<String>('description') ?? '');
    _phoneController = TextEditingController(text: widget.data.get<String>('phone') ?? '');
    _emailController = TextEditingController(text: widget.data.get<String>('email') ?? '');
    _locationController = TextEditingController(text: widget.data.get<String>('location') ?? '');

    _nameController.addListener(_sync);
    _descriptionController.addListener(_sync);
    _phoneController.addListener(_sync);
    _emailController.addListener(_sync);
    _locationController.addListener(_sync);
  }

  void _sync() {
    final updated = widget.data
        .updateData('name', _nameController.text)
        .updateData('description', _descriptionController.text)
        .updateData('phone', _phoneController.text)
        .updateData('email', _emailController.text)
        .updateData('location', _locationController.text);
    widget.onUpdate(updated);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
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
              child: const Icon(Icons.business, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                      color: Colors.red,
                        ),
                  ),
                  Text(
                    'Tell us about your business',
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name *',
                      hintText: 'e.g., AutoCare Kenya',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business, color: Colors.red),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Business Description *',
                    hintText: 'Describe your services and expertise',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description, color: Colors.red),
                  ),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '+254 700 123 456',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone, color: Colors.red),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'info@yourbusiness.co.ke',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, color: Colors.red),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Business Location *',
                    hintText: 'e.g., Westlands, Nairobi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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

class _ProviderServiceSelectionStep extends StatefulWidget {
  final OnboardingData data;
  final Function(OnboardingData) onUpdate;

  const _ProviderServiceSelectionStep({required this.data, required this.onUpdate});

  @override
  State<_ProviderServiceSelectionStep> createState() => _ProviderServiceSelectionStepState();
}

class _ProviderServiceSelectionStepState extends State<_ProviderServiceSelectionStep> {
  bool _loading = true;
  // Keep for future caching or filtering needs; suppress unused warning by referencing length in debug builds.
  List<dynamic> _allServices = [];
  List<dynamic> _categoryServices = [];
  Set<String> _selectedServiceIds = {};
  final Map<String, Map<String, dynamic>> _serviceRequirements = {};
  final Map<String, Map<String, dynamic>> _serviceValues = {};

  Map<String, dynamic>? _findServiceById(String id) {
    for (final s in _categoryServices) {
      final sid = (s['id'] ?? s['service_id'])?.toString();
      if (sid == id) return s as Map<String, dynamic>;
    }
    return null;
  }

  /// Convert pricing fields from string to enhanced_pricing type
  Map<String, dynamic> _convertPricingToEnhanced(Map<String, dynamic> requirements) {
    final converted = Map<String, dynamic>.from(requirements);
    if (!converted.containsKey('fields')) {
      converted['fields'] = [];
    }
    
    final fields = converted['fields'] as List;
    print('🔄 Converting pricing fields in display: $fields');
    
    final pricingFieldIndex = fields.indexWhere((field) => 
      field['name'] == 'pricing' || field['name'] == 'price');
    
    if (pricingFieldIndex != -1) {
      print('🔄 Converting existing pricing field at index $pricingFieldIndex');
      fields[pricingFieldIndex] = {
        "name": "pricing",
        "label": "Service Pricing",
        "type": "enhanced_pricing",
        "required": true
      };
    } else {
      print('➕ Adding new pricing field to display');
      fields.insert(0, {
        "name": "pricing",
        "label": "Service Pricing",
        "type": "enhanced_pricing",
        "required": true
      });
    }
    
    print('✅ AFTER display conversion - Fields: $fields');
    return converted;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final group = widget.data.get<FrontendCategoryGroup>('selectedGroup');
      // Fetch global services from the view (already includes category fields and requirements)
      final raw = await GlobalServiceApi.getAllGlobalServices();

      // Normalize to a consistent shape for the UI layer
      final all = raw.map((s) => {
            'id': s['service_id'],
            'name': s['service_name'],
            'description': s['service_description'],
            'requirements': s['service_requirements'] ?? {},
            'category_id': s['service_category_id'],
            'category_name': s['service_category_name'],
            'created_at': s['service_created_at'],
          }).toList();

      // Determine allowed category NAMES from the selected frontend group (case-insensitive match)
      final allowedNames = _allowedServiceCategoriesForGroup(group?.name ?? '')
          .map((e) => e.toLowerCase())
          .toSet();

      // Filter services by category_name (case-insensitive)
      final filtered = all.where((s) {
        final cname = (s['category_name'] ?? '').toString().toLowerCase();
        return allowedNames.contains(cname);
      }).toList();

      setState(() {
        _allServices = all;
        _categoryServices = filtered;
        _loading = false;
      });

      assert(() {
        // Reference to avoid linter complaining about unused field in release builds
        // and still keep for potential future use.
        // ignore: avoid_print
        print('Loaded services: total=${_allServices.length}');
        return true;
      }());

      // Seed requirements map from service_requirements and persist available services
      for (final s in _categoryServices) {
        final sid = s['id'] as String;
        final req = (s['requirements'] ?? {}) as Map<String, dynamic>;
        _serviceRequirements[sid] = Map<String, dynamic>.from(req);
      }

      final updated = widget.data
          .updateData('availableServices', _categoryServices)
          .updateData('selectedServices', _selectedServiceIds.toList())
          .updateData('serviceRequirements', _serviceRequirements)
          .updateData('serviceValues', _serviceValues);
      widget.onUpdate(updated);
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _syncBackToData() {
    final updated = widget.data
        .updateData('availableServices', _categoryServices)
        .updateData('selectedServices', _selectedServiceIds.toList())
        .updateData('serviceRequirements', _serviceRequirements)
        .updateData('serviceValues', _serviceValues);
    widget.onUpdate(updated);
  }

  Set<String> _allowedServiceCategoriesForGroup(String groupName) {
    // Map frontend group to allowed service categories (union of relevant service categories)
    switch (groupName) {
      case 'Repair & Maintenance':
        return {
          'Oil & Lubrication', 'Filter Maintenance', 'Engine Care',
          'Transmission & Drivetrain', 'Suspension & Steering', 'Brakes & Safety Systems',
          'Cooling System', 'Electrical & Battery', 'Tyres & Wheels',
          'Air Conditioning', 'Body & Paint', 'Inspection & Diagnostics',
        };
      case 'Vehicle Care & Support':
        return {
          'Refueling', 'Car Wash & Detailing', 'Roadside Assistance', 'Vehicle Pickup & Delivery',
        };
      case 'Parts & Accessories':
        return {
          // If needed, map to parts-related service categories
        };
      case 'Insurance & Documentation':
        return {
          'Insurance & Documentation',
        };
      case 'Vehicle Rental':
        return {
          // Rental-related service categories if present
        };
      default:
        return {};
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Services',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                  ),
                  Text(
                    'Choose the services you offer',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Browse and select services'),
              onPressed: _openServiceSelector,
            ),
          ),
        ),
        Expanded(
          child: _selectedServiceIds.isEmpty
              ? Center(
                  child: Text(
                    'No services selected yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: _selectedServiceIds.length,
                  itemBuilder: (context, index) {
                    final serviceId = _selectedServiceIds.elementAt(index);
                    final service = _findServiceById(serviceId);
                    if (service == null) return const SizedBox.shrink();
                    final reqs = _serviceRequirements[serviceId];
                    if (reqs == null) return const SizedBox.shrink();
                    
                    // Ensure pricing field is converted to enhanced_pricing
                    final convertedReqs = _convertPricingToEnhanced(reqs);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'],
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ServiceRequirementsHelper.buildRequirementsForm(
                              convertedReqs,
                              _serviceValues[serviceId] ?? {},
                              (values) {
                                setState(() {
                                  _serviceValues[serviceId] = values;
                                });
                                _syncBackToData();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openServiceSelector() async {
    // Map API shape to EnhancedServiceSelector shape
    final allServicesForSelector = _categoryServices.map<Map<String, dynamic>>((s) => {
          'id': s['id'],
          'name': s['name'],
          'description': s['description'],
          'category': {
            'name': (s['category_name'] ?? '')
          },
          'requirements': _serviceRequirements[s['id']] ?? s['requirements'] ?? s['service_requirements'] ?? {},
        }).toList();

    final selectedForSelector = _selectedServiceIds
        .map((id) => _findServiceById(id))
        .where((s) => s != null)
        .map<Map<String, dynamic>>((s) {
          final m = s as Map<String, dynamic>;
          return {
            'id': m['id'],
            'name': m['name'],
            'description': m['description'],
            'category': {'name': (m['category_name'] ?? '')},
            'requirements': _serviceRequirements[m['id']] ?? m['requirements'] ?? m['service_requirements'] ?? {},
          };
        })
        .toList();

    // Show selector
    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return EnhancedServiceSelector(
          allServices: List<Map<String, dynamic>>.from(allServicesForSelector),
          selectedServices: List<Map<String, dynamic>>.from(selectedForSelector),
          onConfirm: (selected) {
            setState(() {
              _selectedServiceIds = selected.map((e) => e['id'] as String).toSet();
              // Initialize requirements for new selections
              for (final id in _selectedServiceIds) {
                if (!_serviceRequirements.containsKey(id)) {
                  final service = _findServiceById(id);
                  if (service != null) {
                    final reqsFromService = (service['requirements'] ?? service['service_requirements']) as Map<String, dynamic>?;
                    print('🔍 Service: ${service['name']}');
                    print('🔍 reqsFromService: $reqsFromService');
                    print('🔍 reqsFromService != null: ${reqsFromService != null}');
                    print('🔍 reqsFromService.isNotEmpty: ${reqsFromService?.isNotEmpty ?? false}');
                    
                    if (reqsFromService != null && reqsFromService.isNotEmpty) {
                      // Use API requirements but ensure pricing is included
                      final requirements = Map<String, dynamic>.from(reqsFromService);
                      if (!requirements.containsKey('fields')) {
                        requirements['fields'] = [];
                      }
                      
                      // Check if pricing field already exists and convert to enhanced_pricing
                      final fields = requirements['fields'] as List;
                      print('🔍 BEFORE conversion - Fields: $fields');
                      
                      final pricingFieldIndex = fields.indexWhere((field) => 
                        field['name'] == 'pricing' || field['name'] == 'price');
                      
                      if (pricingFieldIndex != -1) {
                        print('🔄 Converting existing pricing field at index $pricingFieldIndex');
                        // Convert existing pricing field to enhanced_pricing
                        fields[pricingFieldIndex] = {
                          "name": "pricing",
                          "label": "Service Pricing",
                          "type": "enhanced_pricing",
                          "required": true
                        };
                      } else {
                        print('➕ Adding new pricing field');
                        // Add pricing field at the beginning
                        fields.insert(0, {
                          "name": "pricing",
                          "label": "Service Pricing",
                          "type": "enhanced_pricing",
                          "required": true
                        });
                      }
                      
                      print('✅ AFTER conversion - Fields: $fields');
                      
                      _serviceRequirements[id] = requirements;
                    } else {
                      print('🔄 Using ServiceRequirementsHelper for service: ${service['name']}');
                      _serviceRequirements[id] = ServiceRequirementsHelper.getServiceRequirements(
                        service['name'],
                        (service['category_name'] ?? ''),
                      );
                      print('🔄 Generated requirements: ${_serviceRequirements[id]}');
                    }
                    _serviceValues[id] = {};
                  }
                }
              }
              _syncBackToData();
            });
          },
        );
      },
    );
  }
}


