// booking_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/global_service_api.dart';

// Helpers (custom widgets)
import 'package:car_platform/BookingPageHelpers/service_selector.dart';
import 'package:car_platform/BookingPageHelpers/provider_selector.dart';

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
  // User & vehicles
  List<dynamic> _vehicles = [];
  String? _selectedVehicleId;
  Map<String, dynamic>? _me;

  // Services & Providers
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _selectedServices = [];

  List<Map<String, dynamic>> _allProviders = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  Map<String, dynamic>? _selectedProvider;

  // Recommendation toggle
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

      final results = await Future.wait([
        ProviderService.getProviders(),
        GlobalServiceApi.getAllGlobalServices(),
      ]);

      final providers = results[0];
      final services = results[1];

      setState(() {
        _vehicles = vehicles;
        _me = me;
        _allProviders = providers.cast<Map<String, dynamic>>();
        _allServices = services.cast<Map<String, dynamic>>();

        if (_vehicles.isNotEmpty && _selectedVehicleId == null) {
          _selectedVehicleId = _vehicles.first["id"].toString();
        }
      });

      // If navigation passed in defaults
      if (widget.service != null) {
        _selectedServices = [Map<String, dynamic>.from(widget.service!)];
      }
      if (widget.provider != null) {
        _selectedProvider = Map<String, dynamic>.from(widget.provider!);
      }

      if (_selectedServices.isNotEmpty) {
        await _applyServiceFilterMulti();
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

  // Ensure provider services are loaded
  Future<void> _ensureProvidersHaveServicesIfNeeded() async {
    final needFetch = _allProviders.any((p) => p["services"] == null);
    if (!needFetch) return;

    try {
      final futures = _allProviders.map((p) async {
        if (p["id"] != null) {
          final services =
              await ProviderService.getProviderServices(p["id"].toString());
          p["services"] = services;

          if (p["provider_services"] == null) {
            final details =
                await ProviderService.getProviderDetails(p["id"].toString());
            p["provider_services"] = details?["provider_services"] ?? [];
          }
        }
      }).toList();

      await Future.wait(futures);
    } catch (e) {
      debugPrint("Failed to enrich provider data: $e");
      for (var p in _allProviders) {
        p["services"] = p["services"] ?? [];
        p["provider_services"] = p["provider_services"] ?? [];
      }
    }
  }

  // Filter providers for multi-service
  Future<void> _applyServiceFilterMulti() async {
    setState(() {
      _providersLoading = true;
      _filteredProviders = [];
      _selectedProvider = null;
    });

    try {
      await _ensureProvidersHaveServicesIfNeeded();

      final selectedIds = _selectedServices.map((s) => s["id"]).toSet();

      final filtered = _allProviders.map((provider) {
        final services = provider["services"] as List? ?? [];
        final providerServices = provider["provider_services"] as List? ?? [];

        final enriched = services.map((s) {
          if (s is! Map) return s;
          final matched = providerServices.firstWhere(
            (ps) => ps["service_id"] == s["id"],
            orElse: () => null,
          );
          return matched != null
              ? {
                  ...s,
                  "price": matched["price"],
                  "duration": matched["duration"]
                }
              : s;
        }).toList();

        final offeredIds = enriched.map((s) => s["id"]).toSet();

        if (_recommendedOnly) {
          // must offer all services
          if (!selectedIds.every(offeredIds.contains)) return null;
        } else {
          // must offer at least one
          if (offeredIds.intersection(selectedIds).isEmpty) return null;
        }

        return {...provider, "services": enriched};
      }).whereType<Map<String, dynamic>>().toList();

      setState(() => _filteredProviders = filtered);

      if (filtered.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("No providers match selected services")));
      }
    } finally {
      setState(() => _providersLoading = false);
    }
  }

  // Service selector modal
  Future<void> _showServiceSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ServiceSelector(
        allServices: _allServices,
        selectedServices: _selectedServices,
        onConfirm: (services) async {
          setState(() => _selectedServices = services);
          await _applyServiceFilterMulti();
        },
      ),
    );
  }

  // Provider selector modal
  Future<void> _showProviderSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProviderSelector(
        filteredProviders: _filteredProviders,
        selectedServices: _selectedServices,
        recommendedOnly: _recommendedOnly,
        selectedProvider: _selectedProvider,
        onSelect: (p) => setState(() => _selectedProvider = p),
      ),
    );
  }

  // Date/time pickers
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

  // Booking (one booking per selected service)
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

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking(s) successful!")));
      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint("Booking failed: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking failed")));
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
      appBar: AppBar(title: const Text("Book Service")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Vehicle selector
            DropdownButtonFormField<String>(
              value: _selectedVehicleId,
              items: _vehicles
                  .map((v) => DropdownMenuItem<String>(
                        value: v["id"].toString(),
                        child: Text(v["display_name"] ??
                            "${v["make"] ?? "Vehicle"}"),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedVehicleId = val),
              decoration: const InputDecoration(
                labelText: "Select Vehicle",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Service selector
            ElevatedButton.icon(
              onPressed: _showServiceSelector,
              icon: const Icon(Icons.build_circle),
              label: Text(_selectedServices.isEmpty
                  ? "Choose Services"
                  : "Selected: ${_selectedServices.map((s) => s["name"]).join(", ")}"),
            ),
            const SizedBox(height: 12),

            // Recommendation toggle
            SwitchListTile(
              title: const Text("Show Recommended Providers"),
              value: _recommendedOnly,
              onChanged: (v) => setState(() => _recommendedOnly = v),
            ),
            const SizedBox(height: 12),

            // Provider selector
            _providersLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _filteredProviders.isEmpty
                        ? null
                        : _showProviderSelector,
                    icon: const Icon(Icons.business),
                    label: Text(_selectedProvider == null
                        ? "Choose Provider"
                        : _selectedProvider!["name"] ?? "Provider"),
                  ),
            const SizedBox(height: 12),

            // Date/time pickers
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
