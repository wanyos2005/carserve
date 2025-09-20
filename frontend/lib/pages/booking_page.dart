// lib/pages/booking_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> provider;
  final Map<String, dynamic> service;

  const BookingPage({
    super.key,
    required this.provider,
    required this.service,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<dynamic> _vehicles = [];
  dynamic _selectedVehicle;
  DateTime? _selectedDate;
  bool _loading = false;
  Map<String, dynamic>? _me;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vehicles = await VehicleService.listVehicles();
    final me = await AuthService.getMe();
    setState(() {
      _vehicles = vehicles;
      _me = me;
    });
  }

  Future<void> _book() async {
    if (_selectedVehicle == null || _selectedDate == null || _me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select vehicle and date")),
      );
      return;
    }

    setState(() => _loading = true);

    final bookingData = {
      "user_id": _me!["id"],
      "vehicle_id": _selectedVehicle["id"],
      "provider_id": widget.provider["id"],
      "service_id": widget.service["id"],
      "scheduled_at": _selectedDate!.toIso8601String(),
    };

    final result = await BookingService.createBooking(bookingData);

    setState(() => _loading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking successful!")),
      );
      Navigator.pop(context, true); // return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create booking")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Booking")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Provider: ${widget.provider["name"]}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Service: ${widget.service["name"]}"),
                  const SizedBox(height: 20),

                  // Vehicle selector
                  DropdownButtonFormField(
                    value: _selectedVehicle,
                    items: _vehicles
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v["make"] ?? "Vehicle ${v["id"]}"),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedVehicle = val),
                    decoration: const InputDecoration(
                      labelText: "Select Vehicle",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date picker
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? "Pick Date"
                          : _selectedDate!.toLocal().toString().split(" ")[0],
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
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),
                  const Spacer(),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _book,
                      child: const Text("Confirm Booking"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
