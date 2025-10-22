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
      appBar: AppBar(title: const Text("Log Provider Services")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _sectionTitle("Service Template"),
                  _templateSelector(),
                  const Divider(height: 30),
                  
                  // Only show form if template is selected
                  if (_selectedTemplate == null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
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
                  ] else ...[
                    _sectionTitle("Guest & Vehicle Info"),
                    _inputField(_guestContactController, "Guest Contact (phone/email)", required: true),
                    _inputField(_vehiclePlateController, "Vehicle Plate (type to autofill)", required: true),
                    _rowFields([
                      _inputField(_vehicleMakeController, "Make"),
                      _inputField(_vehicleModelController, "Model"),
                    ]),
                    _rowFields([
                      _inputField(_yomController, "Year of Manufacture", type: TextInputType.number),
                      _inputField(_fuelTypeController, "Fuel Type"),
                    ]),
                    const Divider(height: 30),
                    _sectionTitle("Service Details"),
                    _inputField(_mileageController, "Mileage (km)", type: TextInputType.number),
                    _dateTile("Date Performed", _performedAt, () => _selectDate(context, false)),
                    const SizedBox(height: 8),

                    if (_services.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "No services in selected template",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.checklist, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Services in ${_selectedTemplate?['name'] ?? 'Selected Template'} (${_services.length} items)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ..._services.asMap().entries.map((entry) {
                      final index = entry.key;
                      final service = entry.value;
                      final isCompleted = service['done'] == true;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: isCompleted ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isCompleted ? Colors.green[300]! : Colors.grey[300]!,
                            width: isCompleted ? 2 : 1,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isCompleted ? Colors.green[50] : Colors.white,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCompleted ? Colors.green[600] : Colors.grey[400],
                              child: Icon(
                                isCompleted ? Icons.check : Icons.radio_button_unchecked,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              service['display_name'],
                              style: TextStyle(
                                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                                color: isCompleted ? Colors.green[800] : Colors.black87,
                              ),
                            ),
                            trailing: Checkbox(
                              value: isCompleted,
                              onChanged: (v) => _toggleDone(index, v),
                              activeColor: Colors.green[600],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: "Service Notes (optional)",
                                    hintText: "Add any notes about this service...",
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.note_add, size: 20),
                                  ),
                                  maxLines: 2,
                                  onChanged: (v) => _updateNotes(index, v),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    // Service completion summary
                    if (_services.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Service Completion Status",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${_services.where((s) => s['done'] == true).length} of ${_services.length} services completed",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_services.where((s) => s['done'] == true).length == _services.length)
                              Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                          ],
                        ),
                      ),
                    ],
                    
                    const Divider(height: 30),
                    _sectionTitle("Mechanic Details"),
                    _inputField(_mechanicNameController, "Mechanic Name"),
                    _inputField(_mechanicContactController, "Mechanic Contact"),
                    const Divider(height: 30),
                    _sectionTitle("Next Service"),
                    _inputField(_nextServiceKmController, "Next Service (km)", type: TextInputType.number),
                    _dateTile("Next Service Date", _nextServiceDate, () => _selectDate(context, true)),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _loading ? null : _submitLog,
                      icon: const Icon(Icons.save),
                      label: const Text("Submit Log"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // --- Helper UI Builders ---
  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _templateSelector() {
    if (_templates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "No Service Templates Found",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Please create service templates first to log services.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select a Service Template:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        ..._templates.map((template) {
          final templateName = template['name'] ?? 'Unnamed Template';
          final itemCount = (template['items'] as List?)?.length ?? 0;
          final isSelected = template == _selectedTemplate;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onTemplateChanged(template),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? Colors.blue[50] : Colors.white,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[400],
                        child: Icon(
                          Icons.dynamic_form,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              templateName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected ? Colors.blue[800] : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$itemCount service${itemCount != 1 ? 's' : ''}",
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _inputField(TextEditingController controller, String label,
      {bool required = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required ? (v) => (v == null || v.isEmpty) ? "Required" : null : null,
      ),
    );
  }

  Widget _rowFields(List<Widget> fields) {
    return Row(
      children: [
        Expanded(child: fields[0]),
        const SizedBox(width: 8),
        Expanded(child: fields[1]),
      ],
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(date == null ? label : "$label: ${DateFormat.yMMMd().format(date)}"),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }
}
