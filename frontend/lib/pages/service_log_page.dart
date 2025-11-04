import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/vehicle_service.dart';
import 'package:driveon_car_platform/services/booking_service.dart';
import 'package:driveon_car_platform/services/provider_service.dart';
import 'package:driveon_car_platform/services/global_service_api.dart';
import 'package:driveon_car_platform/services/auth_service.dart';
import 'package:driveon_car_platform/BookingPageHelpers/enhanced_service_selector.dart';
import 'package:driveon_car_platform/BookingPageHelpers/enhanced_provider_selector.dart';

class ServiceLogPage extends StatefulWidget {
  const ServiceLogPage({super.key});

  @override
  State<ServiceLogPage> createState() => _ServiceLogPageState();
}

class _ServiceLogPageState extends State<ServiceLogPage> {
  bool _loading = false;
  bool _initialLoading = true;

  List<dynamic> _vehicles = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _selectedServices = [];

  Map<String, dynamic>? _selectedProvider;
  Map<String, dynamic>? _me;

  String? _selectedVehicleId;
  DateTime? _performedAt;

  final TextEditingController _mileageCtrl = TextEditingController();
  final TextEditingController _servedByCtrl = TextEditingController();
  final TextEditingController _costCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final me = await AuthService.getMe();
      final vehicles = await VehicleService.listVehicles();
      final services = await GlobalServiceApi.getAllGlobalServices();
      final providers = await ProviderService.getProviders();

      setState(() {
        _me = me;
        _vehicles = vehicles;
        _services = List<Map<String, dynamic>>.from(services);
        _providers = List<Map<String, dynamic>>.from(providers);
        if (_vehicles.isNotEmpty) {
          _selectedVehicleId = _vehicles.first["id"].toString();
        }
      });
    } catch (e, st) {
      debugPrint("❌ Error loading initial data: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load data")),
      );
    } finally {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _pickPerformedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _performedAt ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _performedAt = picked);
  }

  Future<void> _submitLog() async {
    if (_me == null ||
        _selectedVehicleId == null ||
        _selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Combine selected services into one log entry
      final selectedService = _selectedServices.first;
      final serviceItems = {
        "selected": _selectedServices.map((s) => s["name"]).toList(),
      };

      Map<String, dynamic> logData = {
        "user_id": _me!["id"],
        "vehicle_id": _selectedVehicleId,
        "performed_at": _performedAt?.toIso8601String(),
        "mileage_km": int.tryParse(_mileageCtrl.text),
        "notes": _notesCtrl.text,
        "logged_by": "user",
        "served_by": _servedByCtrl.text.isNotEmpty ? _servedByCtrl.text : null,
        "cost": int.tryParse(_costCtrl.text),
        "service_id": selectedService["id"],
        "service_name": selectedService["name"],
        "service_items": serviceItems,
      };

      // Provider logic - now handled by enhanced_provider_selector
      if (_selectedProvider != null) {
        // Handle both possible field names for provider ID and name
        final providerId = _selectedProvider!["provider_id"] ?? _selectedProvider!["id"];
        final providerName = _selectedProvider!["provider_name"] ?? _selectedProvider!["name"];
        
        logData["provider_id"] = providerId;
        logData["provider_name"] = providerName;
        debugPrint("✅ Added provider to logData: $providerId, $providerName");
        debugPrint("🔍 Full selected provider object: $_selectedProvider");
      } else {
        debugPrint("⚠️ WARNING: No provider selected");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Warning: Please select a provider")),
        );
        setState(() => _loading = false);
        return;
      }

      debugPrint("🔍 Final logData before sending: $logData");
      debugPrint("🔍 Selected provider: $_selectedProvider");
      debugPrint("🔍 logData contains provider_id: ${logData.containsKey('provider_id')}");
      debugPrint("🔍 logData contains provider_name: ${logData.containsKey('provider_name')}");
      final response = await BookingService.createServiceLog(logData);

      // Prompt for rating if provider exists
      // Include log ID to prevent duplicate ratings
      try {
        final providerId = _selectedProvider?["provider_id"] ?? _selectedProvider?["id"];
        final uid = _me?["id"];
        final logId = response?["id"]?.toString();
        if (providerId != null && uid != null) {
          await _showRatingDialog(
            userId: uid as int, 
            providerId: providerId as String,
            logId: logId,
          );
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Service logged successfully")),
      );
      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint("❌ Failed to log service: $e\n$st");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to log service")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Log Service")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicleId,
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

            // Service selector
            ListTile(
              leading: const Icon(Icons.build_circle),
              title: Text(
                _selectedServices.isEmpty
                    ? "Select Service(s)"
                    : "${_selectedServices.length} service(s) selected",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => EnhancedServiceSelector(
                  allServices: _services,
                  selectedServices: _selectedServices,
                  isSparePartsMode: false, // Service log is always for services, not parts
                  onConfirm: (list) => setState(() {
                    _selectedServices = list;
                  }),
                ),
              ),
            ),
            const Divider(),

            // Provider section
            ListTile(
              leading: const Icon(Icons.store),
              title: Text(_selectedProvider == null
                  ? "Select Provider"
                  : _selectedProvider!["provider_name"] ?? "Unknown Provider"),
              subtitle: _selectedProvider != null && _selectedProvider!["is_manual"] == true
                  ? const Text("Manual entry", style: TextStyle(fontStyle: FontStyle.italic))
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => EnhancedProviderSelector(
                  filteredProviders: _providers,
                  selectedServices: _selectedServices,
                  recommendedOnly: false,
                  selectedProvider: _selectedProvider,
                  onSelect: (provider) =>
                      setState(() => _selectedProvider = provider),
                ),
              ),
            ),
            const Divider(),

            TextField(
              controller: _mileageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Mileage (km)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _pickPerformedDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _performedAt == null
                    ? "Pick Performed Date"
                    : "Performed: ${_performedAt!.toLocal().toString().split(" ")[0]}",
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _servedByCtrl,
              decoration: const InputDecoration(
                labelText: "Served By (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Total Cost",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitLog,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save Log"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRatingDialog({required int userId, required String providerId, String? bookingId, String? logId}) async {
    int selected = 5;
    final commentCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Rate Provider"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  return StatefulBuilder(
                    builder: (c, setS) => IconButton(
                      icon: Icon(idx <= selected ? Icons.star : Icons.star_border, color: Colors.amber),
                      onPressed: () { setS(() { selected = idx; }); },
                    ),
                  );
                }),
              ),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(labelText: "Comment (optional)"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Skip")),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ProviderService.rateProvider(
                    providerId: providerId,
                    rating: selected,
                    comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                    userId: userId,
                    bookingId: bookingId,
                    logId: logId,
                  );
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
