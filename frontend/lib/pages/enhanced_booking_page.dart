import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/global_service_api.dart';

// Enhanced Helpers
import 'package:car_platform/BookingPageHelpers/enhanced_service_selector.dart';
import 'package:car_platform/BookingPageHelpers/enhanced_provider_selector.dart';
import 'package:car_platform/BookingPageHelpers/purchase_ordering_ui.dart';

// Components
import 'package:car_platform/components/preferences_popover.dart';

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
  bool _recommendedOnly = true;
  
  // Mode toggle: Services vs Spare Parts
  bool _isSparePartsMode = false;
  
  // Main mode toggle: Service Booking vs Purchase/Ordering
  bool _isPurchaseMode = false;

  // Date/time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Loading flags
  bool _loading = false;
  bool _initialLoading = true;
  bool _providersLoading = false;

  @override
  void initState() {
    super.initState();
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
        
        await BookingService.createBooking({
          "user_id": _me!["id"],
          "vehicle_id": _selectedVehicleId,
          "provider_id": providerId,
          "service_id": serviceId,
          "scheduled_at": _selectedDate!.toUtc().toIso8601String(),
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
        title: Text(_isPurchaseMode ? "Purchase Parts" : "Book Service"),
        actions: [
          // Tab-like button for switching modes
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isPurchaseMode = !_isPurchaseMode;
                  // Reset selections when switching modes
                  _selectedServices = [];
                  _selectedProvider = null;
                  _matchedProviders = [];
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
            icon: const Icon(Icons.settings),
            tooltip: "Preferences",
            onPressed: _showPreferencesPopover,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, // Use theme margin from main.dart
          vertical: 16,
        ),
        child: _isPurchaseMode 
            ? PurchaseOrderingUI(
                vehicles: _vehicles,
                selectedVehicleId: _selectedVehicleId,
                me: _me,
                onVehicleChanged: (val) => setState(() => _selectedVehicleId = val),
                onPurchase: _book,
              )
            : _buildServiceBookingUI(),
      ),
    );
  }

  Widget _buildServiceBookingUI() {
    return Column(
      children: [
        // Vehicle Selection
        DropdownButtonFormField<String>(
          value: _selectedVehicleId,
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
            title: const Text("Provider"),
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
                                  _selectedProvider!["location"]?["area"] ?? "Nairobi",
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
                    : Chip(
                        label: Text(_selectedProvider!["rating"]?.toString() ?? "0.0"),
                        backgroundColor: Colors.green[100],
                        avatar: const Icon(Icons.star, size: 16),
                      ),
            onTap: _matchedProviders.isEmpty ? null : _showProviderSelector,
          ),
        ),

        const SizedBox(height: 12),

        // Date and Time Selection
        Row(
          children: [
            Expanded(
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                  title: const Text("Date", style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    _selectedDate == null
                        ? "Tap to select"
                        : _selectedDate!.toLocal().toString().split(" ")[0],
                    style: const TextStyle(fontSize: 12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: _pickDate,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.purple, size: 20),
                  title: const Text("Time", style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    _selectedTime == null
                        ? "Tap to select"
                        : _selectedTime!.format(context),
                    style: const TextStyle(fontSize: 12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: _pickTime,
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

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
    );
  }

  Future<void> _showPreferencesPopover() async {
    await showPreferencesPopover(
      context: context,
      recommendedOnly: _recommendedOnly,
      isPurchaseMode: _isPurchaseMode,
      onRecommendedOnlyChanged: (value) async {
        setState(() => _recommendedOnly = value);
        await _fetchMatchedProviders();
      },
      onApply: () {
        // Refresh providers if needed
        if (_selectedServices.isNotEmpty) {
          _fetchMatchedProviders();
        }
      },
    );
  }

}
