// frontend/lib/pages/edit_our_services_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/global_service_api.dart';
import 'package:car_platform/pages/manage_templates_page.dart';
import 'package:car_platform/BookingPageHelpers/enhanced_service_selector.dart';

class EditOurServicesPage extends StatefulWidget {
  final String providerId;
  const EditOurServicesPage({super.key, required this.providerId});

  @override
  State<EditOurServicesPage> createState() => _EditOurServicesPageState();
}

class _EditOurServicesPageState extends State<EditOurServicesPage> {
  Map<String, dynamic>? _provider;
  List<dynamic> _allServices = [];
  final Map<String, Map<String, TextEditingController>> _serviceFieldControllers = {}; 
  final Map<String, TextEditingController> _displayNameControllers = {};
  final Map<String, Map<String, dynamic>> _pricingData = {}; // Enhanced pricing data
  final Set<String> _selectedServiceIds = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }


  void _showServiceSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedServiceSelector(
        allServices: _allServices.cast<Map<String, dynamic>>(),
        selectedServices: _getSelectedServicesAsList(),
        onConfirm: (services) {
          setState(() {
            _selectedServiceIds.clear();
            _selectedServiceIds.addAll(services.map((s) => s['id'].toString()));
          });
        },
        showPricingConfiguration: true,
        showServiceRequirements: true,
        onPricingChanged: (serviceId, pricingData) {
          setState(() {
            _pricingData[serviceId] = pricingData;
          });
        },
        onDisplayNameChanged: (serviceId, displayName) {
          _displayNameControllers.putIfAbsent(serviceId, () => TextEditingController()).text = displayName;
        },
        initialPricingData: _pricingData,
        initialDisplayNames: _displayNameControllers.map((key, controller) => MapEntry(key, controller.text)),
      ),
    );
  }

  List<Map<String, dynamic>> _getSelectedServicesAsList() {
    return _allServices
        .where((service) {
          final sid = service["service_id"]?.toString() ?? service["id"]?.toString();
          return _selectedServiceIds.contains(sid);
        })
        .map((service) => {
          'id': service["service_id"]?.toString() ?? service["id"]?.toString(),
          'name': service["service_name"]?.toString() ?? service["name"]?.toString(),
          'description': service["service_description"]?.toString() ?? service["description"]?.toString(),
        })
        .toList();
  }

  Future<void> _loadAll() async {
    final prov = await ProviderService.getProviderDetails(widget.providerId);
    final services = await GlobalServiceApi.getAllGlobalServices();
    final attached = await ProviderService.getProviderServices(widget.providerId);

    setState(() {
      _provider = prov;
      _allServices = services;
    });

    for (var a in attached) {
      // Handle the new data structure - service_id is directly available
      final sid = a["service_id"]?.toString();
      if (sid != null && sid.isNotEmpty) {
        _selectedServiceIds.add(sid);

        // Handle display_name
        final displayName = a["display_name"]?.toString() ?? "";
        _displayNameControllers.putIfAbsent(
          sid, () => TextEditingController(text: displayName)
        );

        // Initialize enhanced pricing data
        _pricingData[sid] = {
          'price_type': a["price_type"]?.toString() ?? "range",
          'min_price': a["min_price"]?.toString() ?? "",
          'max_price': a["max_price"]?.toString() ?? "",
          'unit': a["unit"]?.toString() ?? "",
          'negotiable': a["negotiable"] ?? true,
          'currency': 'KES',
          'price': a["price"]?.toString() ?? "", // Legacy field for compatibility
        };

        // Handle metadata/extra_data - the new structure uses extra_data
        final meta = a["extra_data"] as Map<String, dynamic>? ?? {};
        _serviceFieldControllers.putIfAbsent(sid, () {
          final map = <String, TextEditingController>{};
          meta.forEach((k, v) {
            map[k] = TextEditingController(text: v?.toString() ?? "");
          });
          return map;
        });
      }
    }
  }


  Future<void> _save() async {
    try {
      final List<Map<String, dynamic>> payload = [];
      for (var sid in _selectedServiceIds) {
        final metaControllers = _serviceFieldControllers[sid] ?? {};
        final metadata = <String, dynamic>{};
        metaControllers.forEach((k, c) {
          final val = c.text.trim();
          // Handle different data types
          if (val.toLowerCase() == 'true') {
            metadata[k] = true;
          } else if (val.toLowerCase() == 'false') {
            metadata[k] = false;
          } else if (val.isNotEmpty && RegExp(r'^\d+$').hasMatch(val)) {
            metadata[k] = int.tryParse(val);
          } else if (val.isNotEmpty && RegExp(r'^\d*\.?\d+$').hasMatch(val)) {
            metadata[k] = double.tryParse(val);
          } else {
            metadata[k] = val;
          }
        });

        final displayName = _displayNameControllers[sid]?.text.trim();
        final pricingData = _pricingData[sid] ?? {};

        payload.add({
          "service_id": sid,
          "display_name": displayName?.isNotEmpty == true ? displayName : null,
          
          // Enhanced pricing fields
          "min_price": pricingData['min_price'] != null && pricingData['min_price'] != 0.0 ? pricingData['min_price'] : null,
          "max_price": pricingData['max_price'] != null && pricingData['max_price'] != 0.0 ? pricingData['max_price'] : null,
          "price_type": pricingData['price_type'] ?? "range",
          "currency": pricingData['currency'] ?? "KES",
          "unit": pricingData['unit'],
          "negotiable": pricingData['negotiable'] ?? true,
          
          // Legacy price field for backward compatibility
          "price": pricingData['price'] != null && pricingData['price'].toString().isNotEmpty ? pricingData['price'] : null,
          
          "metadata": metadata
        });
      }

      print("🔄 EditOurServicesPage: Saving ${payload.length} services for provider ${widget.providerId}");
      print("🔄 EditOurServicesPage: Payload: $payload");

      final result = await ProviderService.attachServicesToProvider(widget.providerId, payload);
      print("🔄 EditOurServicesPage: API Response: $result");

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Services updated successfully! ${payload.length} services attached."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save services. Please check your connection and try again."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print("❌ EditOurServicesPage: Error saving services: $e");
      print("❌ EditOurServicesPage: Stack trace: $stackTrace");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving services: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_provider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Our Services - ${_provider!["name"] ?? _provider!["provider_name"] ?? ""}"),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.business, color: Colors.blue[700], size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Service Management",
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  Text(
                                    _provider!["description"]?.toString() ?? "",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Select services you offer and configure their pricing. This information will be visible to customers.",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Services Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Our Services",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showServiceSelector,
                      icon: const Icon(Icons.add),
                      label: Text("${_selectedServiceIds.length} Services"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Selected Services Summary
                if (_selectedServiceIds.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Selected Services (${_selectedServiceIds.length})",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap 'Manage Services' to configure pricing and requirements for each service.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedServiceIds.isNotEmpty ? _showServiceSelector : null,
                        icon: const Icon(Icons.settings),
                        label: const Text("Manage Services"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageTemplatesPage(providerId: widget.providerId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.dynamic_form),
                        label: const Text("Templates"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text("Save"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
