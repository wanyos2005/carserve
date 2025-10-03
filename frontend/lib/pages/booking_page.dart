//booking_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/booking_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/global_service_api.dart';

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
  // Data stores
  List<dynamic> _vehicles = [];
  String? _selectedVehicleId;

  Map<String, dynamic>? _me;

  // Services & Providers
  List<Map<String, dynamic>> _allServices = [];
  Map<String, dynamic>? _selectedService;

  List<Map<String, dynamic>> _allProviders = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  Map<String, dynamic>? _selectedProvider;

  // Date/time
  DateTime? _selectedDate; // contains both date+time once both are chosen
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

      // fetch providers and global services concurrently
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

        // prefill from navigation props (if provided)
        if (widget.service != null) {
          _selectedService = Map<String, dynamic>.from(widget.service!);
        }
        if (widget.provider != null) {
          _selectedProvider = Map<String, dynamic>.from(widget.provider!);
        }

        // default vehicle
        if (_vehicles.isNotEmpty && _selectedVehicleId == null) {
          _selectedVehicleId = _vehicles.first["id"].toString();
        }
      });

      // If a service was pre-selected, compute filtered providers now.
      if (_selectedService != null) {
        await _applyServiceFilter(_selectedService!);
      }
    } catch (e, st) {
      debugPrint("Error loading initial booking data: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load booking data.")),
      );
    } finally {
      setState(() => _initialLoading = false);
    }
  }

  // Ensure each provider has a 'services' list (fetch details when missing).
  Future<void> _ensureProvidersHaveServicesIfNeeded() async {
    final needFetch = _allProviders.any((p) => p["services"] == null);
    if (!needFetch) return;

    try {
      final futures = _allProviders.map((p) async {
        if (p["id"] != null) {
          // fetch services
          final services = await ProviderService.getProviderServices(p["id"].toString());
          p["services"] = services;

          // also keep provider_services if not already there
          if (p["provider_services"] == null) {
            final details = await ProviderService.getProviderDetails(p["id"].toString());
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

  // Apply filter: providers that offer `service`
  Future<void> _applyServiceFilter(Map<String, dynamic> service) async {
    setState(() {
      _providersLoading = true;
      _filteredProviders = [];
      _selectedProvider = null;
    });

    try {
      // Ensure each provider has its services and provider_services
      await _ensureProvidersHaveServicesIfNeeded();

      final serviceId = service["id"];

      final filtered = _allProviders.map((provider) {
        final services = provider["services"] as List? ?? [];
        final providerServices = provider["provider_services"] as List? ?? [];

        // Merge provider_services info into each service
        final enrichedServices = services.map((s) {
          if (s is! Map) return s;

          final matched = providerServices.firstWhere(
            (ps) => ps["service_id"] == s["id"],
            orElse: () => null,
          );

          if (matched != null) {
            return {
              ...s,
              "price": matched["price"],
              "duration": matched["duration"],
              "booking_required": matched["booking_required"],
              "extra_data": matched["extra_data"] ?? {},
            };
          }

          return s;
        }).toList();

        // Only keep provider if it offers the selected service
        final serviceIds = enrichedServices.map((s) => s["id"]).toList();
        if (!serviceIds.contains(serviceId)) return null;

        return {
          ...provider,
          "services": enrichedServices,
        };
      }).whereType<Map<String, dynamic>>().toList();

      setState(() {
        _filteredProviders = filtered;
      });

      if (filtered.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No providers offer the selected service")),
        );
      }
    } catch (e) {
      debugPrint("Error filtering/enriching providers: $e");
    } finally {
      setState(() => _providersLoading = false);
    }
  }

  // Show searchable modal to pick a service
  Future<void> _showServiceSelector() async {
    String query = "";
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = _allServices.where((s) {
            final name = (s["name"] ?? "").toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Search services...",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setModalState(() => query = v),
                    ),
                  ),
                  SizedBox(
                    height: 360,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = filtered[i];
                        final subtitle = [
                          if (s["price_range"] != null) s["price_range"],
                          if (s["requirements"] != null && s["requirements"]["duration"] != null)
                            "${s["requirements"]["duration"]}"
                        ].join(" • ");
                        return ListTile(
                          title: Text(s["name"] ?? "Unnamed"),
                          subtitle: subtitle.isEmpty ? null : Text(subtitle),
                          trailing: _selectedService != null && _selectedService!["id"] == s["id"]
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () async {
                            Navigator.pop(ctx);
                            setState(() => _selectedService = Map<String, dynamic>.from(s));
                            await _applyServiceFilter(_selectedService!);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Show searchable modal to pick a provider (uses filtered list)
  Future<void> _showProviderSelector() async {
    String query = "";
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final listSource = _selectedService == null ? _allProviders : _filteredProviders;
          final filtered = listSource.where((p) {
            final name = (p["name"] ?? "").toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Search providers...",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setModalState(() => query = v),
                    ),
                  ),
                  SizedBox(
                    height: 360,
                    child: _providersLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              return ListTile(
                                title: Text(p["name"] ?? "Provider"),
                                subtitle: Text(p["description"] ?? ""),
                                trailing: _selectedProvider != null && _selectedProvider!["id"] == p["id"]
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : null,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() => _selectedProvider = Map<String, dynamic>.from(p));
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
            _selectedTime?.hour ?? 9, _selectedTime?.minute ?? 0);
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0));
    if (t != null) {
      setState(() {
        _selectedTime = t;
        if (_selectedDate != null) {
          _selectedDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, t.hour, t.minute);
        }
      });
    }
  }

  Future<void> _book() async {
    if (_me == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not loaded")));
      return;
    }
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a vehicle")));
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a service")));
      return;
    }
    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a provider")));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select date and optionally time")));
      return;
    }

    setState(() => _loading = true);

    try {
      final bookingData = {
        "user_id": _me!["id"],
        "vehicle_id": _selectedVehicleId,
        "provider_id": _selectedProvider!["id"],
        "service_id": _selectedService!["id"],
        "scheduled_at": _selectedDate!.toUtc().toIso8601String(),
      };

      final res = await BookingService.createBooking(bookingData);
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking successful!")));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create booking")));
      }
    } catch (e, st) {
      debugPrint("Booking failed: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking failed")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _selectedCard({
    required IconData icon,
    required String title,
    required String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 36),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: IconButton(icon: const Icon(Icons.edit), onPressed: onTap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Book Service")),
        body: Center(child: CircularProgressIndicator()),
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
              initialValue: _selectedVehicleId,
              items: _vehicles
                  .map((v) => DropdownMenuItem<String>(
                        value: v["id"].toString(),
                        child: Text(v["display_name"] ?? "${v["make"] ?? "Vehicle"}"),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedVehicleId = val),
              decoration: const InputDecoration(
                labelText: "Select Vehicle",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Service selector (opens modal)
            _selectedService == null
                ? ElevatedButton.icon(
                    onPressed: _showServiceSelector,
                    icon: const Icon(Icons.build_circle),
                    label: const Text("Choose Service"),
                  )
                : _selectedCard(
                    icon: Icons.build_circle,
                    title: _selectedService!["name"] ?? "Service",
                    subtitle: ((_selectedService!["price_range"] ?? "") +
                            ((_selectedService!["requirements"] != null && _selectedService!["requirements"]["duration"] != null)
                                ? " • ${_selectedService!["requirements"]["duration"]}"
                                : ""))
                        .trim(),
                    onTap: _showServiceSelector,
                  ),
            const SizedBox(height: 12),

            // Provider selector
            _providersLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedProvider == null
                    ? ElevatedButton.icon(
                        onPressed: _filteredProviders.isEmpty && _selectedService != null
                            ? () {
                                // if user selected a service but no providers found
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text("No providers available for this service")));
                              }
                            : _showProviderSelector,
                        icon: const Icon(Icons.business),
                        label: Text(_selectedService == null ? "Choose Provider" : "Choose Provider (for selected service)"),
                      )
                    : _selectedCard(
                        icon: Icons.business,
                        title: _selectedProvider!["name"] ?? "Provider",
                        subtitle: _selectedProvider!["description"],
                        onTap: _showProviderSelector,
                      ),
            const SizedBox(height: 12),

            // Date & time pickers
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate == null ? "Pick date" : _selectedDate!.toLocal().toString().split(' ')[0]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime == null ? "Pick time" : _selectedTime!.format(context)),
                  ),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _book,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Confirm Booking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
