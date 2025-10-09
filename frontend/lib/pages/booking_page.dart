import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/global_service_api.dart';

// Helpers
import 'package:car_platform/BookingPageHelpers/service_selector.dart';
import 'package:car_platform/BookingPageHelpers/provider_selector.dart';

//pages
// imports at the top
import 'package:car_platform/pages/service_log_page.dart'; // adjust path as needed


class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? provider;
  final Map<String, dynamic>? service;

  const BookingPage({super.key, this.provider, this.service});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // User & vehicles
  List<dynamic> _vehicles = [];
  String? _selectedVehicleId;
  Map<String, dynamic>? _me;

  // Services & Providers
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _selectedServices = [];
  List<Map<String, dynamic>> _matchedProviders = [];
  Map<String, dynamic>? _selectedProvider;

  // Recommendation toggle (matches backend "match_all")
  bool _recommendedOnly = true;

  // Date/time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Loading flags
  bool _loading = false;
  bool _initialLoading = true;
  bool _providersLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _initialLoading = true);

    try {
      final vehicles = await VehicleService.listVehicles();
      final me = await AuthService.getMe();
      final services = await GlobalServiceApi.getAllGlobalServices();

      setState(() {
        _vehicles = vehicles;
        _me = me;
        _allServices = services.cast<Map<String, dynamic>>();
        if (_vehicles.isNotEmpty && _selectedVehicleId == null) {
          _selectedVehicleId = _vehicles.first["id"].toString();
        }

        // If navigation passed in defaults
        if (widget.service != null) {
          _selectedServices = [Map<String, dynamic>.from(widget.service!)];
        }
        if (widget.provider != null) {
          _selectedProvider = Map<String, dynamic>.from(widget.provider!);
        }
      });

      if (_selectedServices.isNotEmpty) {
        await _fetchMatchedProviders();
      }
    } catch (e, st) {
      debugPrint("Error loading booking data: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load booking data.")),
      );
    } finally {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _fetchMatchedProviders() async {
    if (_selectedServices.isEmpty) return;

    setState(() {
      _providersLoading = true;
      _matchedProviders = [];
      _selectedProvider = null;
    });

    try {
      final serviceIds = _selectedServices.map((s) => s["id"].toString()).toList();
      /* final providers = await ProviderService.getProviders(
        serviceId: null, // We'll pass multiple ids through query params
      ); */

      // 🔹 Use backend multi-service filtering directly
      final queryString = serviceIds.map((id) => "service_ids=$id").join("&");
      final matchAll = _recommendedOnly ? "true" : "false";
      final url = "/service-providers/providers/?$queryString&match_all=$matchAll";
      final filtered = await ProviderService.getProvidersByUrl(url);

      setState(() {
        _matchedProviders = filtered.cast<Map<String, dynamic>>();
      });

      if (filtered.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No providers match selected services")),
        );
      }
    } catch (e) {
      debugPrint("Failed to fetch matched providers: $e");
    } finally {
      setState(() => _providersLoading = false);
    }
  }

  Future<void> _showServiceSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ServiceSelector(
        allServices: _allServices,
        selectedServices: _selectedServices,
        onConfirm: (services) async {
          setState(() => _selectedServices = services);
          await _fetchMatchedProviders();
        },
      ),
    );
  }

  Future<void> _showProviderSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProviderSelector(
        filteredProviders: _matchedProviders,
        selectedServices: _selectedServices,
        recommendedOnly: _recommendedOnly,
        selectedProvider: _selectedProvider,
        onSelect: (p) => setState(() => _selectedProvider = p),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime?.hour ?? 9,
          _selectedTime?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) {
      setState(() {
        _selectedTime = t;
        if (_selectedDate != null) {
          _selectedDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            t.hour,
            t.minute,
          );
        }
      });
    }
  }

  Future<void> _book() async {
    if (_me == null ||
        _selectedVehicleId == null ||
        _selectedServices.isEmpty ||
        _selectedProvider == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      for (var service in _selectedServices) {
        await BookingService.createBooking({
          "user_id": _me!["id"],
          "vehicle_id": _selectedVehicleId,
          "provider_id": _selectedProvider!["id"],
          "service_id": service["id"],
          "scheduled_at": _selectedDate!.toUtc().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Booking(s) successful!")));
      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint("Booking failed: $e\n$st");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Booking failed")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Book Service")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Book Service"),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: "Service Logs",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceLogPage()),
            );
          },
        ),
      ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedVehicleId,
              items: _vehicles
                  .map((v) => DropdownMenuItem<String>(
                        value: v["id"].toString(),
                        child: Text("${v["plate"] ?? ""} ${v["make"] ?? ""} (${v["model"] ?? v["id"]})"),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedVehicleId = val),
              decoration: const InputDecoration(
                labelText: "Select Vehicle",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _showServiceSelector,
              icon: const Icon(Icons.build_circle),
              label: Text(_selectedServices.isEmpty
                  ? "Choose Services"
                  : "Selected: ${_selectedServices.map((s) => s["name"]).join(", ")}"),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text("Show Recommended Providers"),
              value: _recommendedOnly,
              onChanged: (v) async {
                setState(() => _recommendedOnly = v);
                await _fetchMatchedProviders();
              },
            ),
            const SizedBox(height: 12),

            _providersLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _matchedProviders.isEmpty ? null : _showProviderSelector,
                    icon: const Icon(Icons.business),
                    label: Text(_selectedProvider == null
                        ? "Choose Provider"
                        : _selectedProvider!["provider_name"] ?? "Provider"),
                  ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate == null
                        ? "Pick Date"
                        : _selectedDate!.toLocal().toString().split(" ")[0]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime == null
                        ? "Pick Time"
                        : _selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _book,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Confirm Booking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
