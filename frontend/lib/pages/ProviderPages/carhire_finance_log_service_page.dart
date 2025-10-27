import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driveon_car_platform/services/auth_service.dart';
import 'package:driveon_car_platform/services/vehicle_service.dart';
import 'package:driveon_car_platform/services/finance_service.dart';

class CarHireFinanceLogServicePage extends StatefulWidget {
  final String providerId;

  const CarHireFinanceLogServicePage({super.key, required this.providerId});

  @override
  State<CarHireFinanceLogServicePage> createState() =>
      _CarHireFinanceLogServicePageState();
}

class _CarHireFinanceLogServicePageState
    extends State<CarHireFinanceLogServicePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _guestContactController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _loanRateController = TextEditingController();
  final TextEditingController _loanTenureController = TextEditingController();

  DateTime? _applicationDate;
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
    _loanRateController.dispose();
    _loanTenureController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

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
          });
        } else {
          setState(() {
            _vehicleMakeController.clear();
            _vehicleModelController.clear();
          });
        }
      } catch (e) {
        debugPrint("Vehicle lookup failed: $e");
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _applicationDate = picked;
      });
    }
  }

  Future<void> _submitFinance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1️⃣ Create guest
      final guest = await AuthService.createGuestUser(
        email: _guestContactController.text.contains('@')
            ? _guestContactController.text.trim()
            : null,
        phone: !_guestContactController.text.contains('@')
            ? _guestContactController.text.trim()
            : null,
        name: "Finance Client",
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
          "created_by_provider_id": widget.providerId,
        };
        vehicle = await VehicleService.createGuestVehicle(payload);
      }
      final vehicleId = vehicle?["id"];

      // 3️⃣ Submit loan application
      final financePayload = {
        "owner_id": guestId,
        "vehicle_id": vehicleId,
        "provider_id": widget.providerId,
        "loan_rate": _loanRateController.text.trim(),
        "loan_tenure": _loanTenureController.text.trim(),
        "application_date":
            _applicationDate?.toIso8601String().split('.').first,
      };

      final response = await FinanceService.createLoanApplication(financePayload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Finance application logged successfully!")),
      );
      Navigator.pop(context, response);
    } catch (e) {
      debugPrint("❌ Error submitting finance log: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Car Hire / Finance Service")),
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
                  const Divider(height: 30),
                  const Text("Finance / Loan Details",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _loanRateController,
                    decoration: const InputDecoration(
                      labelText: "Loan Rate (%)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _loanTenureController,
                    decoration: const InputDecoration(
                      labelText: "Loan Tenure (Months)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                  ),
                  ListTile(
                    title: Text(_applicationDate == null
                        ? "Select Application Date"
                        : "Application Date: ${DateFormat.yMMMd().format(_applicationDate!)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _submitFinance,
                    icon: const Icon(Icons.save),
                    label: const Text("Submit Loan Record"),
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
