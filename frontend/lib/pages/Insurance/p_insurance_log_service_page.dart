import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driveon_car_platform/services/vehicle_service.dart';
import 'package:driveon_car_platform/services/auth_service.dart';
import 'package:driveon_car_platform/services/insurance_service.dart';

class PInsuranceLogServicePage extends StatefulWidget {
  final String providerId;

  const PInsuranceLogServicePage({super.key, required this.providerId});

  @override
  State<PInsuranceLogServicePage> createState() =>
      _PInsuranceLogServicePageState();
}

class _PInsuranceLogServicePageState extends State<PInsuranceLogServicePage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  final TextEditingController _guestContactController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _fuelTypeController = TextEditingController();
  final TextEditingController _yomController = TextEditingController();
  final TextEditingController _insuranceTypeController = TextEditingController();

  DateTime? _commencementDate;
  DateTime? _expiryDate;
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _vehiclePlateController.addListener(_onPlateChanged);
  }

  @override
  void dispose() {
    _vehiclePlateController.removeListener(_onPlateChanged);
    _guestContactController.dispose();
    _vehiclePlateController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _fuelTypeController.dispose();
    _yomController.dispose();
    _insuranceTypeController.dispose();
    _debounce?.cancel();
    super.dispose();
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
            _yomController.text =
                vehicle['yom'] != null ? vehicle['yom'].toString() : '';
          });
        } else {
          setState(() {
            _vehicleMakeController.clear();
            _vehicleModelController.clear();
            _fuelTypeController.clear();
            _yomController.clear();
          });
        }
      } catch (e) {
        debugPrint("Vehicle lookup failed: $e");
      }
    });
  }

  Future<void> _pickDate(bool isCommencement) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        if (isCommencement) {
          _commencementDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _submitPolicy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1️⃣ Create or find guest user
      final guest = await AuthService.createGuestUser(
        email: _guestContactController.text.contains('@')
            ? _guestContactController.text.trim()
            : null,
        phone: !_guestContactController.text.contains('@')
            ? _guestContactController.text.trim()
            : null,
        name: "Insurance Client",
        providerId: widget.providerId,
      );

      if (guest == null) throw Exception("Failed to create guest user");
      final guestId = guest["id"];

      // 2️⃣ Find or create vehicle
      final plate = _vehiclePlateController.text.trim();
      final existing = await VehicleService.searchVehicles(plate);
      Map<String, dynamic>? vehicle;

      if (existing.isNotEmpty &&
          existing.first['plate'].toString().toUpperCase() ==
              plate.toUpperCase()) {
        vehicle = existing.first;
      } else {
        final payload = {
          "owner_id": guestId,
          "plate": plate,
          "make": _vehicleMakeController.text.trim(),
          "model": _vehicleModelController.text.trim(),
          "yom": int.tryParse(_yomController.text) ?? 0,
          "fuel_type": _fuelTypeController.text.trim(),
          "created_by_provider_id": widget.providerId,
        };
        vehicle = await VehicleService.createGuestVehicle(payload);
      }
      final vehicleId = vehicle?["id"];

      // 3️⃣ Submit insurance policy
      await InsuranceService.createPolicy(
        ownerId: guestId,
        vehicleId: vehicleId,
        providerId: widget.providerId,
        insuranceType: _insuranceTypeController.text.trim(),
        commencementDate: _commencementDate,
        expiryDate: _expiryDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insurance policy logged successfully!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("❌ Error submitting insurance policy: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Insurance Policy")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const Text("Client & Vehicle Info",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _guestContactController,
                    decoration: const InputDecoration(
                      labelText: "Client Contact (phone/email)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _vehiclePlateController,
                    decoration: const InputDecoration(
                      labelText: "Vehicle Plate (type to autofill)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yomController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Year of Manufacture",
                            border: OutlineInputBorder(),
                          ),
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
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text("Insurance Details",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _insuranceTypeController,
                    decoration: const InputDecoration(
                      labelText: "Insurance Type (e.g. Comprehensive)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text(_commencementDate == null
                        ? "Select Commencement Date"
                        : "Commencement: ${DateFormat.yMMMd().format(_commencementDate!)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(true),
                  ),
                  ListTile(
                    title: Text(_expiryDate == null
                        ? "Select Expiry Date"
                        : "Expiry: ${DateFormat.yMMMd().format(_expiryDate!)}"),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () => _pickDate(false),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _submitPolicy,
                    icon: const Icon(Icons.save),
                    label: const Text("Submit Policy"),
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
