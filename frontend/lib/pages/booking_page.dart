// lib/pages/booking_page.dart
// lib/pages/booking_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart'; // to fetch providers
import 'package:car_platform/services/service_catalog.dart'; // mock service list (repair, insurance, etc.)

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

  // Service + provider fields
  List<Map<String, dynamic>> _allProviders = [];
  Map<String, dynamic>? _selectedProvider;
  Map<String, dynamic>? _selectedService;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vehicles = await VehicleService.listVehicles();
    final me = await AuthService.getMe();
    final providers = await ProviderService.listProviders(); // fetch from backend

    debugPrint("🔄 Vehicles fetched: ${vehicles.map((v) => v['id']).toList()}");
    debugPrint("👤 Current user: ${me?['id']}");
    debugPrint("🏢 Providers fetched: ${providers.length}");

    setState(() {
      _vehicles = vehicles;
      _me = me;
      _allProviders = providers.cast<Map<String, dynamic>>();

      // If props were passed → pre-fill
      if (widget.provider != null) {
        _selectedProvider = widget.provider;
      }
      if (widget.service != null) {
        _selectedService = widget.service;
      }

      // Default vehicle
      if (_vehicles.isNotEmpty && _selectedVehicleId == null) {
        _selectedVehicleId = _vehicles.first["id"].toString();
        debugPrint("✅ Auto-selected first vehicle: $_selectedVehicleId");
      }
    });
  }

  Future<void> _book() async {
    debugPrint(
        "📌 Booking attempt with vehicle=$_selectedVehicleId date=$_selectedDate user=${_me?['id']} service=${_selectedService?['id']} provider=${_selectedProvider?['id']}");

    if (_selectedVehicleId == null ||
        _selectedDate == null ||
        _me == null ||
        _selectedService == null ||
        _selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _loading = true);

    final bookingData = {
      "user_id": _me!["id"],
      "vehicle_id": _selectedVehicleId,
      "provider_id": _selectedProvider!["id"],
      "service_id": _selectedService!["id"],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Service"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  // Service dropdown (from catalog or backend)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedService,
                    items: ServiceCatalog.services
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s["name"]),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedService = val;
                        _selectedProvider = null; // reset provider
                      });
                      debugPrint("🛠️ Service selected: ${val?['name']}");
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Service",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Provider dropdown (filtered by service if selected)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedProvider,
                    items: _allProviders
                        .where((p) => _selectedService == null ||
                            (p["services"] as List)
                                .contains(_selectedService!["id"]))
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p["name"]),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedProvider = val);
                      debugPrint("🏢 Provider selected: ${val?['name']}");
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Provider",
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

                  const Spacer(),

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
// lib/pages/booking_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart'; // to fetch providers
import 'package:car_platform/services/service_catalog.dart'; // mock service list (repair, insurance, etc.)

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

  // Service + provider fields
  List<Map<String, dynamic>> _allProviders = [];
  Map<String, dynamic>? _selectedProvider;
  Map<String, dynamic>? _selectedService;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vehicles = await VehicleService.listVehicles();
    final me = await AuthService.getMe();
    final providers = await ProviderService.listProviders(); // fetch from backend

    debugPrint("🔄 Vehicles fetched: ${vehicles.map((v) => v['id']).toList()}");
    debugPrint("👤 Current user: ${me?['id']}");
    debugPrint("🏢 Providers fetched: ${providers.length}");

    setState(() {
      _vehicles = vehicles;
      _me = me;
      _allProviders = providers.cast<Map<String, dynamic>>();

      // If props were passed → pre-fill
      if (widget.provider != null) {
        _selectedProvider = widget.provider;
      }
      if (widget.service != null) {
        _selectedService = widget.service;
      }

      // Default vehicle
      if (_vehicles.isNotEmpty && _selectedVehicleId == null) {
        _selectedVehicleId = _vehicles.first["id"].toString();
        debugPrint("✅ Auto-selected first vehicle: $_selectedVehicleId");
      }
    });
  }

  Future<void> _book() async {
    debugPrint(
        "📌 Booking attempt with vehicle=$_selectedVehicleId date=$_selectedDate user=${_me?['id']} service=${_selectedService?['id']} provider=${_selectedProvider?['id']}");

    if (_selectedVehicleId == null ||
        _selectedDate == null ||
        _me == null ||
        _selectedService == null ||
        _selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _loading = true);

    final bookingData = {
      "user_id": _me!["id"],
      "vehicle_id": _selectedVehicleId,
      "provider_id": _selectedProvider!["id"],
      "service_id": _selectedService!["id"],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Service"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  // Service dropdown (from catalog or backend)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedService,
                    items: ServiceCatalog.services
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s["name"]),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedService = val;
                        _selectedProvider = null; // reset provider
                      });
                      debugPrint("🛠️ Service selected: ${val?['name']}");
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Service",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Provider dropdown (filtered by service if selected)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedProvider,
                    items: _allProviders
                        .where((p) => _selectedService == null ||
                            (p["services"] as List)
                                .contains(_selectedService!["id"]))
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p["name"]),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedProvider = val);
                      debugPrint("🏢 Provider selected: ${val?['name']}");
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Provider",
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

                  const Spacer(),

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
