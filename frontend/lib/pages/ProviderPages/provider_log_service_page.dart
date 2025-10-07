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

 // Vehicle + user
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _guestContactController = TextEditingController();
  final TextEditingController _fuelTypeController = TextEditingController();
  final TextEditingController _yomController = TextEditingController();

  // Service info
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _mechanicNameController = TextEditingController();
  final TextEditingController _mechanicContactController = TextEditingController();
  final TextEditingController _nextServiceKmController = TextEditingController();

  DateTime? _performedAt;
  DateTime? _nextServiceDate;

  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplateServices();
  }

  Future<void> _fetchTemplateServices() async {
    setState(() => _loading = true);
    try {
      final providerServices =
          await ProviderService.getProviderServices(widget.providerId);

      final Map<String, dynamic> serviceMap = {
        for (var ps in providerServices) ps['service_id']: ps
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
          'display_name':
              ps?['display_name'] ?? ps?['service']?['name'] ?? 'Unnamed Service',
          'done': false,
          'notes': '',
        };
      }).toList();

      setState(() => _services = resolvedItems);
    } catch (e) {
      debugPrint("Error fetching template services: $e");
    }
    setState(() => _loading = false);
  }

  void _toggleDone(int index, bool? value) {
    setState(() => _services[index]['done'] = value ?? false);
  }

  void _updateNotes(int index, String value) {
    setState(() => _services[index]['notes'] = value);
  }

  Future<void> _selectDate(BuildContext context, bool isNextService) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isNextService) {
          _nextServiceDate = picked;
        } else {
          _performedAt = picked;
        }
      });
    }
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_services.isEmpty) return;

    setState(() => _loading = true);

    try {
      // 1️⃣ Create guest user first
      final guestUser = await AuthService.createGuestUser(
        email: _guestContactController.text.contains("@")
            ? _guestContactController.text.trim()
            : null,
        phone: !_guestContactController.text.contains("@")
            ? _guestContactController.text.trim()
            : null,
        name: "Guest User",
        providerId: widget.providerId,
      );

      if (guestUser == null) throw Exception("Failed to create guest user");
      final guestId = guestUser["id"];

      // 2️⃣ Create vehicle
      final guestVehiclePayload = {
        "owner_id": guestId,
        "plate": _vehiclePlateController.text.trim(),
        "make": _vehicleMakeController.text.trim(),
        "model": _vehicleModelController.text.trim(),
        "mileage": int.tryParse(_mileageController.text) ?? 0,
        "yom": int.tryParse(_yomController.text) ?? 0,
        "fuel_type": _fuelTypeController.text.trim(),
        "created_by_provider_id": widget.providerId,
      };

      final createdVehicle = await VehicleService.createGuestVehicle(guestVehiclePayload);
      if (createdVehicle == null) throw Exception("Failed to create guest vehicle");

      final vehicleId = createdVehicle["id"];

      // 3️⃣ Log the completed services
      final completed = _services.where((s) => s["done"] == true).toList();
      final logsPayload = completed.map((s) => {
        "provider_id": widget.providerId,
        "vehicle_id": vehicleId,
        "user_id": guestId,
        "service_id": s["service_id"],
        "service_name": s["display_name"],
        "performed_at": _performedAt?.toIso8601String().split('.').first,
        "next_service_km": int.tryParse(_nextServiceKmController.text) ?? 0,
        "next_service_date": _nextServiceDate?.toIso8601String().split('.').first,
        "mileage_km": int.tryParse(_mileageController.text) ?? 0,
        "mechanic_name": _mechanicNameController.text.trim(),
        "mechanic_contact": _mechanicContactController.text.trim(),
        "provider_contact": {
          "contact": _mechanicContactController.text.trim() // <-- wrapped as dict
        },
        "notes": s["notes"],
        "logged_by": "provider",
      }).toList();

      final response = await BookingService.createBulkServiceLogs(logsPayload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged ${response.length} services successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ Error submitting logs: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Services")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const Text("Guest & Vehicle Info",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _guestContactController,
                    decoration: const InputDecoration(
                      labelText: "Guest Contact (phone/email)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _vehiclePlateController,
                    decoration: const InputDecoration(
                      labelText: "Vehicle Plate",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _vehicleMakeController,
                          decoration: const InputDecoration(
                            labelText: "Make",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _vehicleModelController,
                          decoration: const InputDecoration(
                            labelText: "Model",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yomController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Year of Manufacture (YOM)",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _fuelTypeController,
                          decoration: const InputDecoration(
                            labelText: "Fuel Type",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text("Service Details",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mileageController,
                    decoration: const InputDecoration(
                      labelText: "Mileage (km)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  ListTile(
                    title: Text(_performedAt == null
                        ? "Select Date Performed"
                        : "Performed: ${DateFormat.yMMMd().format(_performedAt!)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 10),
                  ..._services.map((service) => Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          title: Text(
                            service['display_name'],
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Checkbox(
                            value: service['done'],
                            onChanged: (value) =>
                                _toggleDone(_services.indexOf(service), value),
                          ),
                          subtitle: TextField(
                            decoration: const InputDecoration(
                              labelText: "Notes",
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            onChanged: (v) =>
                                _updateNotes(_services.indexOf(service), v),
                          ),
                        ),
                      )),
                  const Divider(height: 30),
                  const Text("Mechanic Details",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mechanicNameController,
                    decoration: const InputDecoration(
                      labelText: "Mechanic Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mechanicContactController,
                    decoration: const InputDecoration(
                      labelText: "Mechanic Contact",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Divider(height: 30),
                  const Text("Next Service",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nextServiceKmController,
                    decoration: const InputDecoration(
                      labelText: "Next Service (km)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  ListTile(
                    title: Text(_nextServiceDate == null
                        ? "Select Next Service Date"
                        : "Next Service: ${DateFormat.yMMMd().format(_nextServiceDate!)}"),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () => _selectDate(context, true),
                  ),
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
}
