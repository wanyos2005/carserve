import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/booking_service.dart';
import 'package:driveon_car_platform/services/vehicle_service.dart';
import 'package:driveon_car_platform/services/auth_service.dart';
import 'package:driveon_car_platform/services/provider_service.dart';
import 'package:driveon_car_platform/services/global_service_api.dart';
import 'package:driveon_car_platform/services/location_service.dart';
import 'package:driveon_car_platform/components/location_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// Enhanced Helpers
import 'package:driveon_car_platform/BookingPageHelpers/enhanced_service_selector.dart';
import 'package:driveon_car_platform/BookingPageHelpers/enhanced_provider_selector.dart';


// Components

// Models and Utils
import 'package:driveon_car_platform/models/booking_config.dart';
import 'package:driveon_car_platform/utils/location_display_helper.dart';
import 'package:driveon_car_platform/pages/BookingSteps/booking_step_builders.dart';

//pages
// import 'package:car_platform/pages/service_log_page.dart'; // Removed - handled by main navigation

class EnhancedBookingPage extends StatefulWidget {
  final Map<String, dynamic>? provider;
  final Map<String, dynamic>? service;

  const EnhancedBookingPage({super.key, this.provider, this.service});

  @override
  State<EnhancedBookingPage> createState() => _EnhancedBookingPageState();
}

class _EnhancedBookingPageState extends State<EnhancedBookingPage> {
  // Step-based booking configuration
  late BookingConfig _config;
  late BookingData _data;
  int _currentStep = 0;
  bool _isLoading = false;

  // User & vehicles
  List<dynamic> _vehicles = [];
  String? _selectedVehicleId;
  Map<String, dynamic>? _me;

  // Services & Providers
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _selectedServices = [];
  List<Map<String, dynamic>> _matchedProviders = [];
  Map<String, dynamic>? _selectedProvider;

  // Recommendation toggle (matches backend "match_all")
  bool _recommendedOnly = false;
  
  // Mode toggle: Services vs Spare Parts
  final bool _isSparePartsMode = false;
  
  // Main mode toggle: Service Booking vs Purchase/Ordering
  bool _isPurchaseMode = false;

  // Date/time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Pricing
  final Map<String, double> _servicePrices = {}; // serviceId -> base price
  final Map<String, double> _negotiatedPrices = {}; // serviceId -> negotiated price
  final Map<String, Map<String, dynamic>> _servicePricingInfo = {}; // serviceId -> full pricing info
  bool _hasNegotiated = false;

  // Loading flags
  bool _loading = false;
  bool _initialLoading = true;
  bool _providersLoading = false;
  
  // Communication tracking
  final List<Map<String, dynamic>> _contactHistory = [];
  
  // Location tracking
  Map<String, dynamic>? _customerLocation;
  Map<String, dynamic>? _serviceLocation;

  @override
  void initState() {
    super.initState();
    _config = _isPurchaseMode 
        ? BookingConfigs.getPurchaseConfig() 
        : BookingConfigs.getServiceBookingConfig();
    _data = BookingData();
    _loadInitialData();
  }

  Map<String, dynamic> _normalizeService(Map<String, dynamic> s) {
    // Accepts legacy or view-shaped service and returns unified shape used by UI
    final id = s['id'] ?? s['service_id'];
    final name = s['name'] ?? s['service_name'];
    final description = s['description'] ?? s['service_description'];
    final requirements = s['requirements'] ?? s['service_requirements'] ?? {};
    final categoryName = s['category']?['name'] ?? s['service_category_name'];
    return {
      'id': id,
      'name': name,
      'description': description,
      'requirements': requirements,
      'category_name': categoryName,
      ...s,
    };
  }

  Future<void> _loadInitialData() async {
    setState(() => _initialLoading = true);

    try {
      final vehicles = await VehicleService.listVehicles();
      final me = await AuthService.getMe();
      final services = await GlobalServiceApi.getAllGlobalServices();

      setState(() {
        _vehicles = vehicles;
        _me = me;
        _allServices = services
            .map((s) => Map<String, dynamic>.from(_normalizeService(s)))
            .toList()
            .cast<Map<String, dynamic>>();
        if (_vehicles.isNotEmpty && _selectedVehicleId == null) {
          _selectedVehicleId = _vehicles.first["id"].toString();
        }

        // Parse pricing information for all services
        for (var service in _allServices) {
          final serviceId = service["id"]?.toString() ?? "";
          final pricingInfo = _parseServicePricing(service);
          _servicePricingInfo[serviceId] = pricingInfo;
          _servicePrices[serviceId] = pricingInfo["min_price"] ?? 0.0;
        }

        // If navigation passed in defaults
        if (widget.service != null) {
          _selectedServices = [
            Map<String, dynamic>.from(_normalizeService(widget.service!))
          ];
        }
        if (widget.provider != null) {
          _selectedProvider = Map<String, dynamic>.from(widget.provider!);
        }
      });

      if (_selectedServices.isNotEmpty && widget.provider == null) {
        await _fetchMatchedProviders();
      }
    } catch (e, st) {
      debugPrint("Error loading booking data: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load booking data.")),
      );
    } finally {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _fetchMatchedProviders() async {
    if (_selectedServices.isEmpty) return;

    setState(() {
      _providersLoading = true;
      _matchedProviders = [];
      if (widget.provider == null) {
        _selectedProvider = null;
      }
    });

    try {
      final serviceIds = _selectedServices.map((s) {
        final id = s["id"] ?? s["service_id"] ?? s["service"]?["id"];
        if (id == null) {
          debugPrint("⚠️ Warning: Service object missing ID: $s");
          return null;
        }
        return id.toString();
      }).where((id) => id != null).toList();
      
      // 🔹 Use backend multi-service filtering directly
      final queryString = serviceIds.map((id) => "service_ids=$id").join("&");
      final matchAll = _recommendedOnly ? "true" : "false";
      final url = "/service-providers/providers/?$queryString&match_all=$matchAll";
      final filtered = await ProviderService.getProvidersByUrl(url);

      setState(() {
        _matchedProviders = filtered.cast<Map<String, dynamic>>();
      });

      if (filtered.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No providers match selected services")),
        );
      }
    } catch (e) {
      debugPrint("Failed to fetch matched providers: $e");
    } finally {
      setState(() => _providersLoading = false);
    }
  }

  Future<void> _showServiceSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EnhancedServiceSelector(
        allServices: _allServices,
        selectedServices: _selectedServices,
        isSparePartsMode: _isSparePartsMode,
        isPurchaseMode: _isPurchaseMode,
        onConfirm: (services) async {
          setState(() => _selectedServices = services.map((s) => _normalizeService(s)).toList());
          await _fetchMatchedProviders();
        },
      ),
    );
  }

  Future<void> _showProviderSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EnhancedProviderSelector(
        filteredProviders: _matchedProviders,
        selectedServices: _selectedServices,
        recommendedOnly: _recommendedOnly,
        selectedProvider: _selectedProvider,
        onSelect: (p) => setState(() => _selectedProvider = p),
        customerLocation: _serviceLocation,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime?.hour ?? 9,
          _selectedTime?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) {
      setState(() {
        _selectedTime = t;
        if (_selectedDate != null) {
          _selectedDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            t.hour,
            t.minute,
          );
        }
      });
    }
  }

  Future<void> _book() async {
    if (_isPurchaseMode) {
      await _handlePurchase();
      return;
    }

    if (_me == null ||
        _selectedVehicleId == null ||
        _selectedServices.isEmpty ||
        _selectedProvider == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      for (var service in _selectedServices) {
        // Handle different service object structures
        final serviceId = service["id"] ?? service["service_id"] ?? service["service"]?["id"];
        final providerId = _selectedProvider!["provider_id"] ?? _selectedProvider!["id"];
        
        if (serviceId == null) {
          debugPrint("❌ Error: Service object missing ID: $service");
          throw Exception("Service ID is missing");
        }
        
        if (providerId == null) {
          debugPrint("❌ Error: Provider object missing ID: $_selectedProvider");
          throw Exception("Provider ID is missing");
        }
        
        // Get negotiated price or use base price
        final negotiatedPrice = _negotiatedPrices[serviceId] ?? _servicePrices[serviceId] ?? 0.0;
        final basePrice = _servicePrices[serviceId] ?? 0.0;
        
        await BookingService.createBooking({
          "user_id": _me!["id"],
          "vehicle_id": _selectedVehicleId,
          "provider_id": providerId,
          "service_id": serviceId,
          "scheduled_at": _selectedDate!.toUtc().toIso8601String(),
          "base_price": basePrice,
          "agreed_price": negotiatedPrice,
          "has_negotiated": _hasNegotiated,
          "negotiation_notes": _hasNegotiated ? "Price negotiated with provider" : null,
          "service_location": _serviceLocation,
          "customer_location": _customerLocation,
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Booking(s) successful!")));
      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint("Booking failed: $e\n$st");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Booking failed")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handlePurchase() async {
    // TODO: Implement purchase/ordering logic
    // This would typically involve:
    // 1. Creating a purchase inquiry/quote/order
    // 2. Sending notification to supplier
    // 3. Storing purchase details
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Purchase request submitted successfully!")),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Book Service")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
        actions: [
          // Tab-like button for switching modes
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isPurchaseMode = !_isPurchaseMode;
                  _config = _isPurchaseMode 
                      ? BookingConfigs.getPurchaseConfig() 
                      : BookingConfigs.getServiceBookingConfig();
                  _currentStep = 0;
                  // Reset selections when switching modes
                  _selectedServices = [];
                  _selectedProvider = null;
                  _matchedProviders = [];
                  _data = BookingData();
                });
              },
              icon: Icon(_isPurchaseMode ? Icons.build_circle : Icons.shopping_cart),
              label: Text(_isPurchaseMode ? "Book Service" : "Spare Parts"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPurchaseMode ? Colors.blue : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
           IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: "Provider Filter",
            onPressed: _showProviderFilterDialog,
          ),
        ],
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
    
    // Update data with current state
    _syncDataWithState();
    
    // Use the appropriate step builder with actual data
    switch (step.type) {
      case BookingStepType.vehicleAndService:
        return BookingStepBuilders.buildVehicleAndServiceStep(
          context, 
          _data, 
          _updateData,
                vehicles: _vehicles,
                selectedVehicleId: _selectedVehicleId,
                onVehicleChanged: (val) => setState(() => _selectedVehicleId = val),
          allServices: _allServices,
          selectedServices: _selectedServices,
          onServicesChanged: (services) {
            setState(() {
              _selectedServices = services;
              // Reset provider-related state when services change
              _selectedProvider = null;
              _matchedProviders = [];
            });
            // Immediately fetch providers for the newly selected services
            _fetchMatchedProviders();
          },
          isSparePartsMode: _isSparePartsMode,
          isPurchaseMode: _isPurchaseMode,
        );
      case BookingStepType.providerSelection:
        return BookingStepBuilders.buildProviderSelectionStep(
          context, 
          _data, 
          _updateData,
          matchedProviders: _matchedProviders,
          selectedProvider: _selectedProvider,
          onProviderSelected: (provider) => setState(() => _selectedProvider = provider),
          selectedServices: _selectedServices,
          recommendedOnly: _recommendedOnly,
          providersLoading: _providersLoading,
          serviceLocation: _serviceLocation,
          onCallProvider: _callProvider,
          onWhatsAppProvider: _openWhatsApp,
          onSmsProvider: _sendSMS,
          onEmailProvider: _sendEmail,
          onFilterChanged: (value) async {
            setState(() => _recommendedOnly = value);
            await _fetchMatchedProviders();
          },
        );
      case BookingStepType.schedulingAndLocation:
        return BookingStepBuilders.buildSchedulingAndLocationStep(
          context, 
          _data, 
          _updateData,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onDateChanged: (date) => setState(() => _selectedDate = date),
          onTimeChanged: (time) => setState(() => _selectedTime = time),
          serviceLocation: _serviceLocation,
          onLocationChanged: (location) => setState(() => _serviceLocation = location),
        );
      case BookingStepType.pricingAndConfirmation:
        return BookingStepBuilders.buildPricingAndConfirmationStep(
          context, 
          _data, 
          _updateData,
          selectedServices: _selectedServices,
          selectedProvider: _selectedProvider,
          servicePrices: _servicePrices,
          negotiatedPrices: _negotiatedPrices,
          servicePricingInfo: _servicePricingInfo,
          hasNegotiated: _hasNegotiated,
          onBook: _book,
          onOpenNegotiationDialog: _showPriceNegotiationDialog,
          isLoading: _loading,
        );
    }
  }

  void _syncDataWithState() {
    _data.set('selectedVehicleId', _selectedVehicleId);
    _data.set('selectedServices', _selectedServices);
    _data.set('selectedProvider', _selectedProvider);
    _data.set('selectedDate', _selectedDate);
    _data.set('selectedTime', _selectedTime);
    _data.set('serviceLocation', _serviceLocation);
    _data.set('isSparePartsMode', _isSparePartsMode);
    _data.set('isPurchaseMode', _isPurchaseMode);
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
          'Booking Complete! 🎉',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _config.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your ${_isPurchaseMode ? 'purchase order' : 'service booking'} has been confirmed successfully.',
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
                        ? _finishBooking
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

  void _updateData(BookingData newData) {
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
      _completeBooking();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _finishBooking() {
    Navigator.of(context).pop();
  }

  void _completeBooking() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _book();
      setState(() {
        _currentStep = _config.steps.length; // Move to completion step
      });
    } catch (e) {
      _showErrorDialog('Booking Failed', 'Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Widget _buildServiceBookingUI() {
    return SingleChildScrollView(
      child: Column(
      children: [
        // Vehicle Selection
        DropdownButtonFormField<String>(
          initialValue: _selectedVehicleId,
          items: _vehicles
              .map((v) => DropdownMenuItem<String>(
                    value: v["id"].toString(),
                    child: Text("${v["plate"] ?? ""} ${v["make"] ?? ""} (${v["model"] ?? v["id"]})"),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedVehicleId = val),
          decoration: const InputDecoration(
            labelText: "Select Vehicle",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Service/Parts Selection with enhanced UI
        Card(
          child: ListTile(
            leading: Icon(
              _isSparePartsMode ? Icons.inventory_2 : Icons.build_circle,
              color: _isSparePartsMode ? Colors.orange : Colors.blue,
            ),
            title: Text(_isSparePartsMode ? "Spare Parts" : "Services"),
            subtitle: _selectedServices.isEmpty
                ? Text(_isSparePartsMode 
                    ? "Tap to select spare parts" 
                    : "Tap to select services")
                : Text(_isSparePartsMode
                    ? "${_selectedServices.length} parts selected"
                    : "${_selectedServices.length} services selected"),
            trailing: _selectedServices.isEmpty
                ? const Icon(Icons.arrow_forward_ios)
                : Chip(
                    label: Text("${_selectedServices.length}"),
                    backgroundColor: _isSparePartsMode 
                        ? Colors.orange[100] 
                        : Colors.blue[100],
                  ),
            onTap: _showServiceSelector,
          ),
        ),
        const SizedBox(height: 12),

        // Show selected services (compact)
        if (_selectedServices.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSparePartsMode ? Colors.orange[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSparePartsMode 
                    ? Colors.orange[200]! 
                    : Colors.blue[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      _isSparePartsMode
                          ? "${_selectedServices.length} parts selected"
                          : "${_selectedServices.length} services selected",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isSparePartsMode 
                            ? Colors.orange[800] 
                            : Colors.blue[800],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: _selectedServices.take(3).map((service) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isSparePartsMode 
                          ? Colors.orange[100] 
                          : Colors.blue[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service["name"] ?? (_isSparePartsMode ? "Part" : "Service"),
                      style: TextStyle(
                        fontSize: 10,
                        color: _isSparePartsMode 
                            ? Colors.orange[800] 
                            : Colors.blue[800],
                      ),
                    ),
                  )).toList()
                    ..addAll(_selectedServices.length > 3 ? [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "+${_selectedServices.length - 3} more",
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
        const SizedBox(height: 12),

        // Provider Selection with enhanced UI
        Card(
          child: ListTile(
            leading: const Icon(Icons.business, color: Colors.green),
            title: Row(
              children: [
                const Text("Provider"),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _recommendedOnly ? Colors.blue[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _recommendedOnly ? "Recommended" : "All Matching",
                    style: TextStyle(
                      fontSize: 10,
                      color: _recommendedOnly ? Colors.blue[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
                subtitle: _selectedProvider == null
                    ? Text(_providersLoading
                        ? "Loading providers..."
                        : _matchedProviders.isEmpty
                            ? "No providers available"
                            : _isSparePartsMode
                                ? "Tap to select parts supplier"
                                : "Tap to select provider")
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedProvider!["provider_name"] ?? "Selected Provider",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  LocationDisplayHelper.formatLocationShort(_selectedProvider!["location"]),
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedProvider!["is_registered"])
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "✓",
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                          if (_contactHistory.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${_contactHistory.length}",
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
            trailing: _providersLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _selectedProvider == null
                    ? const Icon(Icons.arrow_forward_ios)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Call button
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () => _callProvider(_selectedProvider!),
                            tooltip: "Call Provider",
                          ),
                          // Message button
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.blue),
                            onPressed: () => _messageProvider(_selectedProvider!),
                            tooltip: "Message Provider",
                          ),
                          // Rating chip
                          Chip(
                            label: Text(_selectedProvider!["rating"]?.toString() ?? "0.0"),
                            backgroundColor: Colors.green[100],
                            avatar: const Icon(Icons.star, size: 16),
                          ),
                        ],
                      ),
            onTap: _matchedProviders.isEmpty ? null : _showProviderSelector,
          ),
        ),

        const SizedBox(height: 12),

        // Price Negotiation Section (NEW)
        if (_selectedProvider != null && _selectedServices.isNotEmpty)
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        "Pricing & Negotiation",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "💡 Tip: Call or message the provider to discuss pricing before booking!",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._selectedServices.map((service) => _buildServicePricingCard(service)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showPriceNegotiationDialog(),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("Update Prices"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _hasNegotiated ? null : () => _markAsNegotiated(),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text("I've Negotiated"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasNegotiated ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Date and Time Selection - Compact horizontal layout
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
          children: [
            Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Date", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(
                    _selectedDate == null
                                  ? "Select date"
                        : _selectedDate!.toLocal().toString().split(" ")[0],
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
            Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.purple, size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Time", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(
                    _selectedTime == null
                                  ? "Select time"
                        : _selectedTime!.format(context),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                          ],
                        ),
                      ],
                ),
              ),
            ),
          ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Location Selection Section
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      "Service Location",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "💡 Specify where you need the service (home, office, roadside, etc.)",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Service location picker
                LocationPicker(
                  label: "Where do you need the service?",
                  hint: "Tap to select service location",
                  onLocationSelected: (location) {
                    setState(() => _serviceLocation = location);
                    _calculateProviderDistances();
                  },
                  showCurrentLocationButton: true,
                ),
                
                // Show distance to selected provider
                if (_selectedProvider != null && _serviceLocation != null) ...[
                  const SizedBox(height: 12),
                  _buildDistanceInfo(),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Book Button with Pricing Summary
        Column(
          children: [
            // Pricing Summary
            if (_selectedServices.isNotEmpty && _selectedProvider != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Cost:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          "KES ${_calculateTotalCost().toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    if (_hasNegotiated)
                      const SizedBox(height: 4),
                    if (_hasNegotiated)
                      Text(
                        "✅ Negotiated prices included",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            
            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _book,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isSparePartsMode 
                            ? "Confirm Parts Order" 
                            : "Confirm Booking", 
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }

  Future<void> _showProviderFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Provider Filter"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose how providers are matched to your selected services:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            RadioListTile<bool>(
              title: const Text("Recommended Only"),
              subtitle: const Text("Show only providers that can handle ALL selected services"),
              value: true,
              groupValue: _recommendedOnly,
              onChanged: (value) {
                setState(() => _recommendedOnly = value!);
                Navigator.pop(context);
                _fetchMatchedProviders();
              },
            ),
            RadioListTile<bool>(
              title: const Text("All Matching"),
              subtitle: const Text("Show providers that can handle ANY of the selected services"),
              value: false,
              groupValue: _recommendedOnly,
              onChanged: (value) {
                setState(() => _recommendedOnly = value!);
                Navigator.pop(context);
                _fetchMatchedProviders();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _callProvider(Map<String, dynamic> provider) async {
    final phone = provider["contact_info"]?["phone"] ?? provider["phone"];
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provider phone number not available")),
      );
      return;
    }

    // Show call confirmation dialog
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Call Provider"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Call ${provider["provider_name"] ?? "Provider"}?"),
            const SizedBox(height: 8),
            Text("Phone: $phone"),
            const SizedBox(height: 8),
            const Text(
              "💡 Tip: Discuss pricing, availability, and service details before booking!",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Call"),
          ),
        ],
      ),
    );

    if (shouldCall == true) {
      await _makePhoneCall(phone);
    }
  }

  Future<void> _messageProvider(Map<String, dynamic> provider) async {
    // Show messaging options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Message ${provider["provider_name"] ?? "Provider"}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text("WhatsApp"),
              subtitle: const Text("Quick messaging"),
              onTap: () {
                Navigator.pop(context);
                _openWhatsApp(provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.blue),
              title: const Text("SMS"),
              subtitle: const Text("Text message"),
              onTap: () {
                Navigator.pop(context);
                _sendSMS(provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.orange),
              title: const Text("Email"),
              subtitle: const Text("Detailed inquiry"),
              onTap: () {
                Navigator.pop(context);
                _sendEmail(provider);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text("Call Directly"),
              subtitle: const Text("Make a phone call"),
              onTap: () {
                Navigator.pop(context);
                _callProvider(provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(Map<String, dynamic> provider) async {
    final phone = provider["contact_info"]?["phone"] ?? provider["phone"];
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provider phone number not available")),
      );
      return;
    }
    
    // Remove any non-digit characters and add country code if needed
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final whatsappPhone = cleanPhone.startsWith('254') ? cleanPhone : '254$cleanPhone';
    
    // Create a contextual message based on selected services
    final serviceNames = _selectedServices.map((s) => s["name"] ?? "Service").join(", ");
    final message = _selectedServices.isNotEmpty 
        ? "Hello! I'm interested in your services for: $serviceNames. Can we discuss pricing and availability?"
        : "Hello! I'm interested in your automotive services. Can we discuss pricing and availability?";
    
    final url = "https://wa.me/$whatsappPhone?text=${Uri.encodeComponent(message)}";
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        _trackCommunication("whatsapp", phone);
      } else {
        throw Exception("Cannot launch WhatsApp");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open WhatsApp: $e")),
      );
    }
  }

  Future<void> _sendSMS(Map<String, dynamic> provider) async {
    final phone = provider["contact_info"]?["phone"] ?? provider["phone"];
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provider phone number not available")),
      );
      return;
    }
    
    // Create a contextual message based on selected services
    final serviceNames = _selectedServices.map((s) => s["name"] ?? "Service").join(", ");
    final message = _selectedServices.isNotEmpty 
        ? "Hello! I'm interested in your services for: $serviceNames. Can we discuss pricing and availability?"
        : "Hello! I'm interested in your automotive services. Can we discuss pricing and availability?";
    
    final url = "sms:$phone?body=${Uri.encodeComponent(message)}";
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        _trackCommunication("sms", phone);
      } else {
        throw Exception("Cannot launch SMS app");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open SMS: $e")),
      );
    }
  }

  Future<void> _sendEmail(Map<String, dynamic> provider) async {
    final email = provider["contact_info"]?["email"] ?? provider["email"];
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provider email not available")),
      );
      return;
    }
    
    // Create contextual subject and body based on selected services
    final serviceNames = _selectedServices.map((s) => s["name"] ?? "Service").join(", ");
    final subject = _selectedServices.isNotEmpty 
        ? "Service Inquiry - $serviceNames"
        : "Service Inquiry - ${provider["provider_name"] ?? "Provider"}";
    
    final body = _buildEmailBody(provider, serviceNames);
    final url = "mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}";
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        _trackCommunication("email", email);
      } else {
        throw Exception("Cannot launch email app");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open email: $e")),
      );
    }
  }

  Widget _buildServicePricingCard(Map<String, dynamic> service) {
    final serviceId = service["id"]?.toString() ?? "";
    final serviceName = service["name"] ?? "Service";
    final pricingInfo = _servicePricingInfo[serviceId] ?? {};
    final basePrice = _servicePrices[serviceId] ?? 0.0;
    final negotiatedPrice = _negotiatedPrices[serviceId] ?? basePrice;
    
    final priceType = pricingInfo["price_type"] ?? "range";
    final minPrice = pricingInfo["min_price"] ?? 0.0;
    final maxPrice = pricingInfo["max_price"] ?? 0.0;
    final currency = pricingInfo["currency"] ?? "KES";
    final unit = pricingInfo["unit"];
    final isNegotiable = pricingInfo["negotiable"] ?? true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildPriceTypeIndicator(priceType, minPrice, maxPrice, currency, unit),
                    if (isNegotiable)
                      Text(
                        "💬 Negotiable",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[600],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$currency ${negotiatedPrice.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: negotiatedPrice != basePrice ? Colors.green[700] : Colors.blue[700],
                    ),
                  ),
                  if (negotiatedPrice != basePrice)
                    Text(
                      "✅ Negotiated",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTypeIndicator(String priceType, double minPrice, double maxPrice, String currency, String? unit) {
    switch (priceType) {
      case "fixed":
        return Text(
          "Fixed: $currency ${minPrice.toStringAsFixed(0)}",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        );
      case "range":
        return Text(
          "Range: $currency ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)}",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        );
      case "per_unit":
        final unitText = unit == "per_liter" ? "/liter" : unit == "per_hour" ? "/hour" : "/unit";
        return Text(
          "Per Unit: $currency ${minPrice.toStringAsFixed(0)}$unitText",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        );
      case "free":
        return Text(
          "Free Service",
          style: TextStyle(fontSize: 12, color: Colors.green[600]),
        );
      case "variable":
        return Text(
          "Price Varies",
          style: TextStyle(fontSize: 12, color: Colors.orange[600]),
        );
      default:
        return Text(
          "Price: $currency ${minPrice.toStringAsFixed(0)}",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        );
    }
  }

  Future<void> _showPriceNegotiationDialog() async {
    final serviceId = _selectedServices.first["id"]?.toString() ?? "";
    final serviceName = _selectedServices.first["name"] ?? "Service";
    final pricingInfo = _servicePricingInfo[serviceId] ?? {};
    final currentPrice = _negotiatedPrices[serviceId] ?? _servicePrices[serviceId] ?? 0.0;
    
    final priceController = TextEditingController(text: currentPrice > 0 ? currentPrice.toStringAsFixed(0) : "");
    
    final priceType = pricingInfo["price_type"] ?? "range";
    final minPrice = pricingInfo["min_price"] ?? 0.0;
    final maxPrice = pricingInfo["max_price"] ?? 0.0;
    final currency = pricingInfo["currency"] ?? "KES";
    final isNegotiable = pricingInfo["negotiable"] ?? true;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Service Price"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Service: $serviceName", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Show pricing information
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Provider's Pricing:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                  const SizedBox(height: 4),
                  _buildPriceTypeIndicator(priceType, minPrice, maxPrice, currency, pricingInfo["unit"]),
                  if (isNegotiable)
                    Text("💬 This price is negotiable", style: TextStyle(fontSize: 12, color: Colors.orange[600])),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Agreed Price ($currency)",
                border: const OutlineInputBorder(),
                prefixText: "$currency ",
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "💡 Enter the price you agreed with the provider after negotiation",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (price >= 0) { // Allow 0 for free services
                setState(() {
                  _negotiatedPrices[serviceId] = price;
                  _hasNegotiated = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Price updated successfully!")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid price")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _markAsNegotiated() {
    setState(() {
      _hasNegotiated = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Great! You can now proceed with booking.")),
    );
  }

  double _calculateTotalCost() {
    double total = 0.0;
    for (var service in _selectedServices) {
      final serviceId = service["id"]?.toString() ?? "";
      final negotiatedPrice = _negotiatedPrices[serviceId] ?? _servicePrices[serviceId] ?? 0.0;
      total += negotiatedPrice;
    }
    return total;
  }

  /// Parse pricing information from service data (handles both legacy and new formats)
  Map<String, dynamic> _parseServicePricing(Map<String, dynamic> service) {
    final serviceId = service["id"]?.toString() ?? "";
    
    // Check if we have new structured pricing fields
    if (service["min_price"] != null || service["max_price"] != null) {
      return {
        "service_id": serviceId,
        "price_type": service["price_type"] ?? "range",
        "min_price": service["min_price"]?.toDouble() ?? 0.0,
        "max_price": service["max_price"]?.toDouble() ?? 0.0,
        "currency": service["currency"] ?? "KES",
        "unit": service["unit"],
        "negotiable": service["negotiable"] ?? true,
        "display_price": service["price"], // Legacy field for display
        "is_structured": true,
      };
    }
    
    // Fall back to legacy string parsing
    final priceString = service["price"] ?? "";
    final parsed = _parseLegacyPriceString(priceString);
    
    return {
      "service_id": serviceId,
      "price_type": parsed["type"],
      "min_price": parsed["min_price"],
      "max_price": parsed["max_price"],
      "currency": "KES",
      "unit": parsed["unit"],
      "negotiable": true,
      "display_price": priceString,
      "is_structured": false,
    };
  }

  /// Parse legacy price string format (e.g., "KSh 3,500 - 8,000", "KSh 1,500", "Free")
  Map<String, dynamic> _parseLegacyPriceString(String priceString) {
    if (priceString.isEmpty) {
      return {"type": "free", "min_price": 0.0, "max_price": 0.0, "unit": null};
    }
    
    final lowerPrice = priceString.toLowerCase().trim();
    
    // Handle free services
    if (lowerPrice == "free") {
      return {"type": "free", "min_price": 0.0, "max_price": 0.0, "unit": null};
    }
    
    // Handle variable pricing
    if (lowerPrice.contains("varies")) {
      return {"type": "variable", "min_price": 0.0, "max_price": 0.0, "unit": null};
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
      return {"type": "free", "min_price": 0.0, "max_price": 0.0, "unit": unit};
    }
    
    if (numbers.length == 1) {
      return {
        "type": unit != null ? "per_unit" : "fixed",
        "min_price": numbers[0],
        "max_price": numbers[0],
        "unit": unit,
      };
    }
    
    if (numbers.length >= 2) {
      final minPrice = numbers.reduce((a, b) => a < b ? a : b);
      final maxPrice = numbers.reduce((a, b) => a > b ? a : b);
      return {
        "type": unit != null ? "per_unit" : "range",
        "min_price": minPrice,
        "max_price": maxPrice,
        "unit": unit,
      };
    }
    
    return {"type": "free", "min_price": 0.0, "max_price": 0.0, "unit": null};
  }

  /// Helper method to make phone calls
  Future<void> _makePhoneCall(String phone) async {
    final url = "tel:$phone";
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        _trackCommunication("phone_call", phone);
      } else {
        throw Exception("Cannot make phone call");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to make phone call: $e")),
      );
    }
  }

  /// Track communication attempts for analytics and user experience
  void _trackCommunication(String method, String contact) {
    final timestamp = DateTime.now();
    final entry = {
      "method": method,
      "contact": contact,
      "timestamp": timestamp,
      "provider_id": _selectedProvider?["provider_id"] ?? _selectedProvider?["id"],
      "provider_name": _selectedProvider?["provider_name"],
      "services": _selectedServices.map((s) => s["name"]).toList(),
    };
    
    setState(() {
      _contactHistory.add(entry);
    });
    
    // Show helpful tip after first contact
    if (_contactHistory.length == 1) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("💡 Tip: After contacting the provider, you can update prices in the pricing section!"),
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  /// Show quick contact options for the selected provider
  Future<void> _showQuickContactOptions() async {
    if (_selectedProvider == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Contact ${_selectedProvider!["provider_name"] ?? "Provider"}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _callProvider(_selectedProvider!);
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text("Call", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openWhatsApp(_selectedProvider!);
                    },
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text("WhatsApp", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendSMS(_selectedProvider!);
                    },
                    icon: const Icon(Icons.sms),
                    label: const Text("SMS"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendEmail(_selectedProvider!);
                    },
                    icon: const Icon(Icons.email),
                    label: const Text("Email"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Contact history
            if (_contactHistory.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          "Contact History (${_contactHistory.length})",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._contactHistory.take(3).map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            _getContactIcon(entry["method"]),
                            size: 12,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${_formatContactMethod(entry["method"])} - ${_formatTime(entry["timestamp"])}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (_contactHistory.length > 3)
                      Text(
                        "+${_contactHistory.length - 3} more contacts",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Provider info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Provider Information:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Name: ${_selectedProvider!["provider_name"] ?? "N/A"}"),
                  Text("Location: ${LocationDisplayHelper.formatLocationForDisplay(_selectedProvider!["location"])}"),
                  if (_selectedProvider!["contact_info"]?["phone"] != null)
                    Text("Phone: ${_selectedProvider!["contact_info"]?["phone"]}"),
                  if (_selectedProvider!["contact_info"]?["email"] != null)
                    Text("Email: ${_selectedProvider!["contact_info"]?["email"]}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build email body
  String _buildEmailBody(Map<String, dynamic> provider, String serviceNames) {
    final providerName = provider["provider_name"] ?? "Provider";
    final location = provider["location"]?["area"] ?? "Nairobi";
    
    return """
Hello $providerName,

I hope this email finds you well. I'm interested in your automotive services and would like to discuss the following:

${_selectedServices.isNotEmpty ? "Services I'm interested in: $serviceNames" : "General automotive services"}

I would like to discuss:
1. Pricing for the services I need
2. Availability and scheduling
3. Any special requirements or questions I might have

${_selectedVehicleId != null ? "Vehicle Details: ${_vehicles.firstWhere((v) => v["id"].toString() == _selectedVehicleId, orElse: () => {})["make"] ?? "N/A"} ${_vehicles.firstWhere((v) => v["id"].toString() == _selectedVehicleId, orElse: () => {})["model"] ?? "N/A"}" : ""}

I'm located in the $location area and would appreciate if you could provide:
- A quote for the services
- Your availability for the next few days
- Any additional information about your services

Please let me know when would be a good time to discuss this further. You can reach me via:
- Phone: [Your phone number]
- Email: [Your email]

Thank you for your time, and I look forward to hearing from you soon.

Best regards,
[Your name]

---
This inquiry was sent through the Car Platform app.
""";
  }

  /// Helper method to get contact icon based on method
  IconData _getContactIcon(String method) {
    switch (method) {
      case "phone_call":
        return Icons.phone;
      case "whatsapp":
        return Icons.chat;
      case "sms":
        return Icons.sms;
      case "email":
        return Icons.email;
      default:
        return Icons.contact_phone;
    }
  }

  /// Helper method to format contact method for display
  String _formatContactMethod(String method) {
    switch (method) {
      case "phone_call":
        return "Phone Call";
      case "whatsapp":
        return "WhatsApp";
      case "sms":
        return "SMS";
      case "email":
        return "Email";
      default:
        return "Contact";
    }
  }

  /// Helper method to format timestamp for display
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${difference.inDays}d ago";
    }
  }

  /// Calculate distances to all matched providers
  void _calculateProviderDistances() {
    if (_serviceLocation == null || _matchedProviders.isEmpty) return;
    
    for (var provider in _matchedProviders) {
      final providerLocation = provider["location"];
      if (providerLocation != null && 
          providerLocation["latitude"] != null && 
          providerLocation["longitude"] != null) {
        
        final distance = LocationService.calculateProviderDistance(
          _serviceLocation!,
          providerLocation,
        );
        
        if (distance != null) {
          provider["distance_km"] = distance;
          provider["distance_display"] = LocationService.formatDistance(distance);
        }
      }
    }
    
    // Sort providers by distance
    _matchedProviders.sort((a, b) {
      final distanceA = a["distance_km"] ?? double.infinity;
      final distanceB = b["distance_km"] ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });
    
    setState(() {});
  }

  /// Build distance information widget
  Widget _buildDistanceInfo() {
    if (_selectedProvider == null || _serviceLocation == null) {
      return const SizedBox.shrink();
    }
    
    final providerLocation = _selectedProvider!["location"];
    if (providerLocation == null) {
      return const SizedBox.shrink();
    }
    
    final distance = LocationService.calculateProviderDistance(
      _serviceLocation!,
      providerLocation,
    );
    
    if (distance == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.directions, color: Colors.blue[600], size: 16),
          const SizedBox(width: 8),
          Text(
            "Distance to provider: ",
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
          Text(
            LocationService.formatDistance(distance),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const Spacer(),
          if (distance < 5)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "Nearby",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (distance < 20)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "Moderate",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "Far",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

}
