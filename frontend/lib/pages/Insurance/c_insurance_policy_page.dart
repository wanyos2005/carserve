import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Services
import 'package:driveon_car_platform/services/auth_service.dart';
import 'package:driveon_car_platform/services/vehicle_service.dart';
import 'package:driveon_car_platform/services/provider_service.dart';
import 'package:driveon_car_platform/services/insurance_service.dart';
import 'package:driveon_car_platform/BookingPageHelpers/enhanced_provider_selector.dart';
import 'package:driveon_car_platform/services/alerts_service.dart';

class CInsurancePolicyPage extends StatefulWidget {
  const CInsurancePolicyPage({super.key});

  @override
  State<CInsurancePolicyPage> createState() => _CInsurancePolicyPageState();
}

class _CInsurancePolicyPageState extends State<CInsurancePolicyPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedVehicle;
  String? _selectedProvider;
  String? _customProviderName;
  String? _insuranceType;
  DateTime? _commencementDate;
  DateTime? _expiryDate;
  bool _reminderEnabled = true;

  List<dynamic> _vehicles = [];
  List<dynamic> _providers = [];

  bool _loading = false;
  bool _showCustomProviderInput = false;
  Map<String, dynamic>? _selectedProviderMap;

  @override
  void initState() {
    super.initState();
    _loadVehiclesAndProviders();
  }

  Future<void> _loadVehiclesAndProviders() async {
    final vehicles = await VehicleService.listVehicles();
    final providers = await ProviderService.getProviders();

    setState(() {
      _vehicles = vehicles;
      _providers = providers;
    });
  }

  Future<void> _openProviderSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return EnhancedProviderSelector(
          filteredProviders: _providers.cast<Map<String, dynamic>>(),
          selectedServices: const [],
          recommendedOnly: false,
          selectedProvider: _selectedProviderMap,
          onSelect: (provider) {
            setState(() {
              _selectedProviderMap = provider;
              _selectedProvider = provider['provider_id']?.toString();
              _showCustomProviderInput = false;
              _customProviderName = null;
            });
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _commencementDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final me = await AuthService.getMe();
      final ownerId = me?["id"];

      String? providerId = _selectedProvider;

      // If "other" is selected, create a new provider first
      if (_selectedProvider == "other" && _customProviderName != null && _customProviderName!.isNotEmpty) {
        debugPrint("🔄 Creating new provider: ${_customProviderName!.trim()}");
        final newProvider = await ProviderService.quickCreateProvider(_customProviderName!.trim());
        debugPrint("🔄 Provider creation response: $newProvider");
        if (newProvider != null) {
          providerId = newProvider["id"];
          debugPrint("✅ Created new provider: ${newProvider["name"]} with ID: $providerId");
        } else {
          debugPrint("❌ Provider creation returned null");
          throw Exception("Failed to create provider");
        }
      }

      await InsuranceService.createPolicy(
        ownerId: ownerId!,
        vehicleId: _selectedVehicle!,
        providerId: providerId!,
        insuranceType: _insuranceType!,
        commencementDate: _commencementDate,
        expiryDate: _expiryDate,
      );

      // Upsert user preference for insurance expiry reminders based on toggle
      try {
        await AlertsService.upsertPreference(
          userId: ownerId,
          alertType: 'insurance_expiry',
          isEnabled: _reminderEnabled,
          channels: const ['in_app', 'email', 'sms'],
        );
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Insurance policy created successfully!")),
      );
      Navigator.pop(context, true); // return success
    } catch (e) {
      debugPrint("❌ Error creating insurance policy: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Insurance - Add Policy"),
    ),
    body: _buildAddPolicyForm(),
  );
}

Widget _buildAddPolicyForm() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Select Vehicle"),
            items: _vehicles
                .map((v) => DropdownMenuItem<String>(
                      value: v["id"].toString(),
                      child: Text(
                        "${v["plate"] ?? ""} ${v["make"] ?? ""} (${v["model"] ?? v["id"]})",
                      ),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedVehicle = val),
            validator: (val) => val == null ? "Please select a vehicle" : null,
          ),
          const SizedBox(height: 16),

          // Provider selector using EnhancedProviderSelector
          FormField<String>(
            validator: (_) => (_selectedProvider == null && !_showCustomProviderInput)
                ? "Please select or enter a provider"
                : (_showCustomProviderInput && (_customProviderName == null || _customProviderName!.isEmpty))
                    ? "Please enter provider name"
                    : null,
            builder: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _openProviderSelector,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Select Provider',
                        errorText: state.errorText,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedProviderMap != null
                                  ? (_selectedProviderMap!["provider_name"] ?? _selectedProviderMap!["name"] ?? 'Selected provider')
                                  : 'Tap to choose from providers',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showCustomProviderInput = !_showCustomProviderInput;
                          if (_showCustomProviderInput) {
                            _selectedProvider = 'other';
                            _selectedProviderMap = null;
                          } else {
                            if (_selectedProvider == 'other') {
                              _selectedProvider = null;
                            }
                            _customProviderName = null;
                          }
                        });
                      },
                      child: Text(_showCustomProviderInput
                          ? 'Cancel manual entry'
                          : 'Provider not listed? Enter manually'),
                    ),
                  ),
                  if (_showCustomProviderInput) ...[
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Enter Provider Name",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _customProviderName = val),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // If "Other" selected → show text field
          if (_selectedProvider == "other")
            TextFormField(
              decoration:
                  const InputDecoration(labelText: "Enter Provider Name"),
              onChanged: (val) => _customProviderName = val,
              validator: (val) {
                if (_selectedProvider == "other" &&
                    (val == null || val.isEmpty)) {
                  return "Please enter provider name";
                }
                return null;
              },
            ),
          const SizedBox(height: 16),

          // Insurance Type
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Insurance Type"),
            items: const [
              DropdownMenuItem(
                  value: "comprehensive", child: Text("Comprehensive")),
              DropdownMenuItem(value: "third_party", child: Text("Third Party")),
            ],
            onChanged: (val) => setState(() => _insuranceType = val),
            validator: (val) =>
                val == null ? "Please select insurance type" : null,
          ),
          const SizedBox(height: 16),

          // Start Date Picker
          Row(
            children: [
              Expanded(
                child: Text(
                  _commencementDate == null
                      ? "Start date not selected"
                      : "Start: ${DateFormat.yMMMd().format(_commencementDate!)}",
                ),
              ),
              TextButton(
                onPressed: () => _selectDate(context, true),
                child: const Text("Pick Start Date"),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expiry Date Picker
          Row(
            children: [
              Expanded(
                child: Text(
                  _expiryDate == null
                      ? "Expiry date not selected"
                      : "Expiry: ${DateFormat.yMMMd().format(_expiryDate!)}",
                ),
              ),
              TextButton(
                onPressed: () => _selectDate(context, false),
                child: const Text("Pick Expiry Date"),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reminder Switch
          SwitchListTile(
            value: _reminderEnabled,
            onChanged: (val) async {
              setState(() => _reminderEnabled = val);
              final me = await AuthService.getMe();
              final ownerId = me?["id"];
              if (ownerId != null) {
                try {
                  await AlertsService.upsertPreference(
                    userId: ownerId,
                    alertType: 'insurance_expiry',
                    isEnabled: val,
                    channels: const ['in_app', 'email', 'sms'],
                  );
                } catch (_) {}
              }
            },
            title: const Text("Enable Expiry Reminder"),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: const Text("Save Policy"),
            ),
          ),
        ],
      ),
    ),
  );
}
// Removed My Policies tab; list view handled in dashboard
}
