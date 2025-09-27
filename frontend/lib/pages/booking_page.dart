// lib/pages/booking_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? provider;
  final Map<String, dynamic>? service;

  const BookingPage({
    super.key,
    this.provider,
    this.service,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<dynamic> _vehicles = [];
  String? _selectedVehicleId;
  DateTime? _selectedDate;
  bool _loading = false;
  Map<String, dynamic>? _me;

  late bool _isBookMode;
  bool get _hasProviderAndService =>
      widget.provider != null && widget.service != null;

  // Log mode fields
  final _logProviderController = TextEditingController();
  final _logServiceController = TextEditingController();
  final _logNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isBookMode = _hasProviderAndService; // auto-detect mode
    _loadData();
  }

  Future<void> _loadData() async {
    final vehicles = await VehicleService.listVehicles();
    final me = await AuthService.getMe();

    debugPrint("🔄 Vehicles fetched: ${vehicles.map((v) => v['id']).toList()}");
    debugPrint("👤 Current user: ${me?['id']}");

    setState(() {
      _vehicles = vehicles;
      _me = me;
      if (_vehicles.isNotEmpty && _selectedVehicleId == null) {
        _selectedVehicleId = _vehicles.first["id"].toString();
        debugPrint("✅ Auto-selected first vehicle: $_selectedVehicleId");
      }
    });
  }


  Future<void> _book() async {
    debugPrint("📌 Booking attempt with vehicle=$_selectedVehicleId date=$_selectedDate user=${_me?['id']}");
    if (_selectedVehicleId == null || _selectedDate == null || _me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select vehicle and date")),
      );
      return;
    }

    setState(() => _loading = true);

    final bookingData = {
      "user_id": _me!["id"],
      "vehicle_id": _selectedVehicleId,
      "provider_id": widget.provider!["id"],
      "service_id": widget.service!["id"],
      "scheduled_at": _selectedDate!.toIso8601String(),
    };

    final result = await BookingService.createBooking(bookingData);

    setState(() => _loading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking successful!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create booking")),
      );
    }
  }

  Future<void> _logService() async {
    debugPrint("📌 Logging service with vehicle=$_selectedVehicleId user=${_me?['id']}");
    if (_selectedVehicleId == null || _me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select vehicle")),
      );
      return;
    }

    setState(() => _loading = true);

    final logData = {
      "user_id": _me!["id"],
      "vehicle_id": _selectedVehicleId,
      "provider_name": _logProviderController.text.isNotEmpty
          ? _logProviderController.text
          : null,
      "service_name": _logServiceController.text.isNotEmpty
          ? _logServiceController.text
          : null,
      "service_details": _logNotesController.text.isNotEmpty
          ? {"notes": _logNotesController.text}
          : null,
      "performed_at": DateTime.now().toIso8601String(),
    };

    final result = await BookingService.createServiceLog(logData);

    setState(() => _loading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service log saved successfully!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save service log")),
      );
    }
  }

  @override
  void dispose() {
    _logProviderController.dispose();
    _logServiceController.dispose();
    _logNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isBookMode ? "Confirm Booking" : "Log Service"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasProviderAndService) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text("Book"),
                          selected: _isBookMode,
                          onSelected: (_) => setState(() => _isBookMode = true),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text("Log"),
                          selected: !_isBookMode,
                          onSelected: (_) =>
                              setState(() => _isBookMode = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Vehicle dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleId,
                    items: _vehicles
                        .map((v) => DropdownMenuItem<String>(
                              value: v["id"].toString(),
                              child: Text(v["make"] ?? "Vehicle ${v["id"]}"),
                            ))
                        .toList(),
                    onChanged: (val) {
                      debugPrint("🚗 Vehicle selected: $val");
                      setState(() => _selectedVehicleId = val);
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Vehicle",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Book mode
                  if (_isBookMode) ...[
                    Text("Provider: ${widget.provider!["name"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Service: ${widget.service!["name"]}"),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? "Pick Date"
                            : _selectedDate!
                                .toLocal()
                                .toString()
                                .split(" ")[0],
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 60)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                            debugPrint("📅 Date selected: $_selectedDate");
                          });
                        }
                      },
                    ),
                  ],

                  // Log mode
                  if (!_isBookMode) ...[
                    TextField(
                      controller: _logProviderController,
                      decoration: const InputDecoration(
                        labelText: "Provider Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _logServiceController,
                      decoration: const InputDecoration(
                        labelText: "Service Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _logNotesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Notes (optional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBookMode ? _book : _logService,
                      child: Text(_isBookMode ? "Confirm Booking" : "Save Log"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
