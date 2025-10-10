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
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchTemplateServices();
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

  // 🔹 Fetch provider's active service template
  Future<void> _fetchTemplateServices() async {
    setState(() => _loading = true);
    try {
      final providerServices = await ProviderService.getProviderServices(widget.providerId);
      final serviceMap = {
        for (var ps in providerServices) ps['service_id']: ps,
      };

      final templates = await ProviderService.getServiceTemplates(widget.providerId);
      if (templates.isEmpty) {
        setState(() => _services = []);
        return;
      }

      final activeTemplate = templates.first;
      final items = List<Map<String, dynamic>>.from(activeTemplate['items'] ?? []);
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
      debugPrint("Error fetching template services: $e");
    } finally {
      setState(() => _loading = false);
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
                    const Center(child: Text("No service templates found.")),
                  ..._services.map((s) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(s['display_name']),
                          trailing: Checkbox(
                            value: s['done'],
                            onChanged: (v) => _toggleDone(_services.indexOf(s), v),
                          ),
                          subtitle: TextField(
                            decoration: const InputDecoration(labelText: "Notes", isDense: true),
                            maxLines: 1,
                            onChanged: (v) => _updateNotes(_services.indexOf(s), v),
                          ),
                        ),
                      )),
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
              ),
            ),
    );
  }

  // --- Helper UI Builders ---
  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

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
