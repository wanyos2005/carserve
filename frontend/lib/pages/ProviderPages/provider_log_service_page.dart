import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';

class ProviderLogServicePage extends StatefulWidget {
  final String providerId;

  const ProviderLogServicePage({super.key, required this.providerId});

  @override
  State<ProviderLogServicePage> createState() => _ProviderLogServicePageState();
}

class _ProviderLogServicePageState extends State<ProviderLogServicePage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _guestContactController = TextEditingController();
  final TextEditingController _fuelTypeController = TextEditingController();
  final TextEditingController _yomController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _mechanicNameController = TextEditingController();
  final TextEditingController _mechanicContactController = TextEditingController();
  final TextEditingController _nextServiceKmController = TextEditingController();
  
  // Cost tracking for each service
  Map<int, TextEditingController> _serviceCostControllers = {};

  DateTime? _performedAt;
  DateTime? _nextServiceDate;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _templates = [];
  Map<String, dynamic>? _selectedTemplate;
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
    _vehiclePlateController.addListener(_onPlateChanged);
  }

  @override
  void dispose() {
    _vehiclePlateController.removeListener(_onPlateChanged);
    _vehiclePlateController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _guestContactController.dispose();
    _fuelTypeController.dispose();
    _yomController.dispose();
    _mileageController.dispose();
    _mechanicNameController.dispose();
    _mechanicContactController.dispose();
    _nextServiceKmController.dispose();
    
    // Dispose cost controllers
    for (var controller in _serviceCostControllers.values) {
      controller.dispose();
    }
    _serviceCostControllers.clear();
    
    _debounce?.cancel();
    super.dispose();
  }

  // 🔹 Fetch all templates
  Future<void> _fetchTemplates() async {
    setState(() => _loading = true);
    try {
      final templates = await ProviderService.getServiceTemplates(widget.providerId);
      setState(() {
        _templates = templates.cast<Map<String, dynamic>>();
        if (templates.isNotEmpty) {
          _selectedTemplate = templates.first;
          _loadTemplateServices(_selectedTemplate!);
        }
      });
    } catch (e) {
      debugPrint("Error fetching templates: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🔹 Load services for selected template
  Future<void> _loadTemplateServices(Map<String, dynamic> template) async {
    setState(() => _loading = true);
    try {
      final providerServices = await ProviderService.getProviderServices(widget.providerId);
      final serviceMap = {
        for (var ps in providerServices) ps['service_id']: ps,
      };

      final items = List<Map<String, dynamic>>.from(template['items'] ?? []);
      final resolvedItems = items.map((item) {
        final ps = serviceMap[item['service_id']];
        return {
          'service_id': item['service_id'],
          'display_name': ps?['display_name'] ?? ps?['service']?['name'] ?? 'Unnamed Service',
          'done': false,
          'notes': '',
        };
      }).toList();

      // Initialize cost controllers for each service
      for (int i = 0; i < resolvedItems.length; i++) {
        if (!_serviceCostControllers.containsKey(i)) {
          _serviceCostControllers[i] = TextEditingController();
        }
      }
      
      setState(() => _services = resolvedItems);
    } catch (e) {
      debugPrint("Error loading template services: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🔹 Handle template selection
  void _onTemplateChanged(Map<String, dynamic>? template) {
    if (template != null) {
      setState(() {
        _selectedTemplate = template;
      });
      _loadTemplateServices(template);
    }
  }

  // 🔹 Debounced vehicle lookup
  void _onPlateChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final plate = _vehiclePlateController.text.trim();
      if (plate.length < 3) return;

      try {
        final results = await VehicleService.searchVehicles(plate);
        if (results.isNotEmpty) {
          final vehicle = results.first;
          setState(() {
            _vehicleMakeController.text = vehicle['make'] ?? '';
            _vehicleModelController.text = vehicle['model'] ?? '';
            _fuelTypeController.text = vehicle['fuel_type'] ?? '';
            _yomController.text = vehicle['yom']?.toString() ?? '';
            _mileageController.text = vehicle['mileage']?.toString() ?? '';
          });
        } else {
          _vehicleMakeController.clear();
          _vehicleModelController.clear();
          _fuelTypeController.clear();
          _yomController.clear();
          _mileageController.clear();
        }
      } catch (e) {
        debugPrint("Vehicle search error: $e");
      }
    });
  }

  // 🔹 Date pickers
  Future<void> _selectDate(BuildContext context, bool isNext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isNext) _nextServiceDate = picked;
        else _performedAt = picked;
      });
    }
  }

  // 🔹 Toggle service completion
  void _toggleDone(int index, bool? value) {
    setState(() => _services[index]['done'] = value ?? false);
  }

  void _updateNotes(int index, String value) {
    setState(() => _services[index]['notes'] = value);
  }

  void _updateServiceCost(int index, String value) {
    setState(() => _services[index]['cost'] = value);
  }

  // 🔹 Submit log
  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_services.isEmpty) return;

    setState(() => _loading = true);
    try {
      // Guest user
      final guestUser = await AuthService.createGuestUser(
        email: _guestContactController.text.contains("@") ? _guestContactController.text.trim() : null,
        phone: !_guestContactController.text.contains("@") ? _guestContactController.text.trim() : null,
        name: "Guest User",
        providerId: widget.providerId,
      );

      if (guestUser == null) throw Exception("Failed to create guest user");
      final guestId = guestUser["id"];

      // Vehicle
      final plate = _vehiclePlateController.text.trim();
      final existing = await VehicleService.searchVehicles(plate);
      Map<String, dynamic>? vehicle;

      if (existing.isNotEmpty && existing.first['plate'].toString().toUpperCase() == plate.toUpperCase()) {
        vehicle = existing.first;
      } else {
        final payload = {
          "owner_id": guestId,
          "plate": plate,
          "make": _vehicleMakeController.text.trim(),
          "model": _vehicleModelController.text.trim(),
          "mileage": int.tryParse(_mileageController.text) ?? 0,
          "yom": int.tryParse(_yomController.text) ?? 0,
          "fuel_type": _fuelTypeController.text.trim(),
          "created_by_provider_id": widget.providerId,
        };
        vehicle = await VehicleService.createGuestVehicle(payload);
      }

      if (vehicle == null) throw Exception("Failed to find or create vehicle");

      final provider = await ProviderService.getProviderDetails(widget.providerId);
      final providerName = provider?["provider_name"] ?? "Unknown Provider";
      final providerContact = provider?["contact_info"] ?? {};

      final completed = _services.where((s) => s["done"] == true).toList();
      final logsPayload = completed.map((s) => {
        "provider_id": widget.providerId,
        "provider_name": providerName,
        "provider_contact": providerContact,
        "vehicle_id": vehicle!["id"],
        "user_id": guestId,
        "service_id": s["service_id"],
        "service_name": s["display_name"],
        "service_items": {"notes": s["notes"], "checked": s["done"]},
        "performed_at": _performedAt?.toIso8601String().split('.').first,
        "next_service_km": int.tryParse(_nextServiceKmController.text) ?? 0,
        "next_service_date": _nextServiceDate?.toIso8601String().split('.').first,
        "mileage_km": int.tryParse(_mileageController.text) ?? 0,
        "served_by": _mechanicNameController.text.trim(),
        "served_by_contact": _mechanicContactController.text.trim(),
        "logged_by": "provider",
        "notes": s["notes"],
        "cost": int.tryParse(s["cost"]?.toString() ?? "0") ?? 0,
      }).toList();

      final response = await BookingService.createBulkServiceLogs(logsPayload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged ${response.length} services for $plate")),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ Error submitting logs: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Provider Services"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Compact Template Selection
                    _buildCompactTemplateSelector(),
                    const SizedBox(height: 16),
                    
                    // Only show form if template is selected
                    if (_selectedTemplate == null) ...[
                      _buildTemplateSelectionPrompt(),
                    ] else ...[
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Compact Guest & Vehicle Info
                              _buildCompactGuestVehicleSection(),
                              const SizedBox(height: 16),
                              
                              // Compact Service Details
                              _buildCompactServiceSection(),
                              const SizedBox(height: 16),
                              
                              // Compact Mechanic & Next Service
                              _buildCompactMechanicSection(),
                              const SizedBox(height: 20),
                              
                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _loading ? null : _submitLog,
                                  icon: const Icon(Icons.save),
                                  label: const Text("Submit Log"),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // --- Helper UI Builders ---

  // Compact Template Selector
  Widget _buildCompactTemplateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dynamic_form, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  "Service Template",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_templates.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "No templates available",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedTemplate,
                decoration: const InputDecoration(
                  labelText: "Select Template",
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _templates.map((template) {
                  final templateName = template['name'] ?? 'Unnamed Template';
                  final itemCount = (template['items'] as List?)?.length ?? 0;
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: template,
                    child: Text("$templateName ($itemCount services)"),
                  );
                }).toList(),
                onChanged: _onTemplateChanged,
              ),
          ],
        ),
      ),
    );
  }

  // Template Selection Prompt
  Widget _buildTemplateSelectionPrompt() {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 48),
              const SizedBox(height: 16),
              Text(
                "Please Select a Template First",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose a service template above to continue with logging services.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact Guest & Vehicle Section
  Widget _buildCompactGuestVehicleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  "Guest & Vehicle Info",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _compactInputField(_guestContactController, "Guest Contact (phone/email)", required: true),
            const SizedBox(height: 8),
            _compactInputField(_vehiclePlateController, "Vehicle Plate (type to autofill)", required: true),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _compactInputField(_vehicleMakeController, "Make")),
                const SizedBox(width: 8),
                Expanded(child: _compactInputField(_vehicleModelController, "Model")),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _compactInputField(_yomController, "Year", type: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _compactInputField(_fuelTypeController, "Fuel Type")),
              ],
            ),
            const SizedBox(height: 8),
            _compactInputField(_mileageController, "Mileage (km)", type: TextInputType.number),
          ],
        ),
      ),
    );
  }

  // Compact Service Section
  Widget _buildCompactServiceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_circle, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  "Service Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                const Spacer(),
                if (_services.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_services.where((s) => s['done'] == true).length}/${_services.length}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _compactDateTile("Date Performed", _performedAt, () => _selectDate(context, false)),
            const SizedBox(height: 8),
            
            if (_services.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "No services in selected template",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ..._services.asMap().entries.map((entry) {
                final index = entry.key;
                final service = entry.value;
                final isCompleted = service['done'] == true;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: _buildCompactServiceItem(index, service, isCompleted),
                );
              }),
              
              // Cost Summary
              if (_services.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildCostSummary(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Compact Service Item
  Widget _buildCompactServiceItem(int index, Map<String, dynamic> service, bool isCompleted) {
    return Container(
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green[300]! : Colors.grey[300]!,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: isCompleted ? Colors.green[600] : Colors.grey[400],
              child: Icon(
                isCompleted ? Icons.check : Icons.radio_button_unchecked,
                color: Colors.white,
                size: 14,
              ),
            ),
            title: Text(
              service['display_name'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.green[800] : Colors.black87,
              ),
            ),
            trailing: Checkbox(
              value: isCompleted,
              onChanged: (v) => _toggleDone(index, v),
              activeColor: Colors.green[600],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _serviceCostControllers[index],
                        decoration: InputDecoration(
                          labelText: "Cost (KES)",
                          hintText: "0",
                          isDense: true,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          prefixIcon: const Icon(Icons.attach_money, size: 16),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _updateServiceCost(index, v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "Notes (optional)",
                          hintText: "Add notes...",
                          isDense: true,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          prefixIcon: const Icon(Icons.note_add, size: 16),
                        ),
                        maxLines: 1,
                        onChanged: (v) => _updateNotes(index, v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Compact Mechanic Section
  Widget _buildCompactMechanicSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin, color: Colors.purple[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  "Mechanic & Next Service",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _compactInputField(_mechanicNameController, "Mechanic Name")),
                const SizedBox(width: 8),
                Expanded(child: _compactInputField(_mechanicContactController, "Mechanic Contact")),
              ],
            ),
            const SizedBox(height: 8),
            _compactInputField(_nextServiceKmController, "Next Service (km)", type: TextInputType.number),
            const SizedBox(height: 8),
            _compactDateTile("Next Service Date", _nextServiceDate, () => _selectDate(context, true)),
          ],
        ),
      ),
    );
  }

  // Compact Input Field
  Widget _compactInputField(TextEditingController controller, String label,
      {bool required = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? "Required" : null : null,
    );
  }

  // Compact Date Tile
  Widget _compactDateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null ? label : "$label: ${DateFormat.yMMMd().format(date)}",
                style: TextStyle(
                  fontSize: 14,
                  color: date == null ? Colors.grey[600] : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cost Summary Widget
  Widget _buildCostSummary() {
    final totalCost = _calculateTotalCost();
    final completedServices = _services.where((s) => s['done'] == true).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green[700], size: 16),
              const SizedBox(width: 8),
              Text(
                "Cost Summary",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Completed Services: ${completedServices.length}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                ),
              ),
              Text(
                "Total: KES ${totalCost.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          if (completedServices.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...completedServices.map((service) {
              final cost = int.tryParse(service['cost']?.toString() ?? "0") ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      service['display_name'] ?? 'Service',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[600],
                      ),
                    ),
                    Text(
                      "KES ${cost.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // Calculate total cost
  double _calculateTotalCost() {
    double total = 0.0;
    for (var service in _services) {
      if (service['done'] == true) {
        final cost = int.tryParse(service['cost']?.toString() ?? "0") ?? 0;
        total += cost.toDouble();
      }
    }
    return total;
  }


}
