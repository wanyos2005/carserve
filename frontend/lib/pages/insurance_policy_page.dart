import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Services
import 'package:car_platform/services/auth_service.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/insurance_service.dart';

class InsurancePolicyPage extends StatefulWidget {
  const InsurancePolicyPage({super.key});

  @override
  State<InsurancePolicyPage> createState() => _InsurancePolicyPageState();
}

class _InsurancePolicyPageState extends State<InsurancePolicyPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedVehicle;
  String? _selectedProvider;
  String? _insuranceType;
  DateTime? _commencementDate;
  DateTime? _expiryDate;
  bool _reminderEnabled = true;

  List<dynamic> _vehicles = [];
  List<dynamic> _providers = [];

  bool _loading = false;

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

    final me = await AuthService.getMe();
    final ownerId = me?["id"];

    final payload = {
      "owner_id": ownerId,
      "vehicle_id": _selectedVehicle,
      "provider_id": _selectedProvider,
      "insurance_type": _insuranceType,
      "commencement_date": _commencementDate?.toUtc().toIso8601String(),
      "expiry_date": _expiryDate?.toUtc().toIso8601String(),
    };

  final res = await InsuranceService.createPolicy(payload);

    setState(() => _loading = false);

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Insurance policy created successfully!")),
      );
      Navigator.pop(context, true); // return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to create policy.")),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text("Insurance"),
        bottom: const TabBar(
          tabs: [
            Tab(text: "Add Policy"),
            Tab(text: "My Policies"),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _buildAddPolicyForm(),
          _buildMyPoliciesList(),
        ],
      ),
    ),
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

          // Provider Dropdown with "Other" option
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Select Provider"),
            items: [
              ..._providers.map((p) => DropdownMenuItem<String>(
                    value: p["id"].toString(),
                    child: Text(p["name"] ?? "Provider ${p["id"]}"),
                  )),
              const DropdownMenuItem<String>(
                value: "other",
                child: Text("Other (Not Listed)"),
              ),
            ],
            onChanged: (val) => setState(() => _selectedProvider = val),
            validator: (val) =>
                val == null ? "Please select or enter a provider" : null,
          ),
          const SizedBox(height: 16),

          // If "Other" selected → show text field
          if (_selectedProvider == "other")
            TextFormField(
              decoration:
                  const InputDecoration(labelText: "Enter Provider Name"),
              onChanged: (val) => _selectedProvider = val,
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
            onChanged: (val) => setState(() => _reminderEnabled = val),
            title: const Text("Enable Expiry Reminder"),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text("Save Policy"),
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _buildMyPoliciesList() {
  return FutureBuilder(
    future: _loadPoliciesWithDetails(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text("Error: ${snapshot.error}"));
      }
      final policies = snapshot.data as List<Map<String, dynamic>>;
      if (policies.isEmpty) {
        return const Center(child: Text("No policies found."));
      }

      return ListView.builder(
        itemCount: policies.length,
        itemBuilder: (context, index) {
          final policy = policies[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(
                "${policy["vehicle"]?["plate"] ?? "Unknown"} - ${policy["vehicle"]?["make"] ?? ""} ${policy["vehicle"]?["model"] ?? ""}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Provider: ${policy["provider"]?["name"] ?? "Unknown"}"),
                  Text("Type: ${policy["insurance_type"] ?? "-"}"),
                  Text(
                    "Start: ${policy["commencement_date"] != null ? DateFormat.yMMMd().format(DateTime.parse(policy["commencement_date"])) : "-"}",
                  ),
                  Text(
                    "Expiry: ${policy["expiry_date"] != null ? DateFormat.yMMMd().format(DateTime.parse(policy["expiry_date"])) : "-"}",
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Fetches policies and enriches with vehicle + provider details
Future<List<Map<String, dynamic>>> _loadPoliciesWithDetails() async {
  final me = await AuthService.getMe();
  final ownerId = me?["id"];
  if (ownerId == null) return [];

  final policies = await InsuranceService.getPoliciesByOwner(ownerId.toString());

  List<Map<String, dynamic>> enriched = [];

  for (var policy in policies) {
    Map<String, dynamic>? vehicle;
    Map<String, dynamic>? provider;

    if (policy["vehicle_id"] != null) {
      try {
        final v = await VehicleService.getByVehicleId(policy["vehicle_id"].toString());
        if (v is Map<String, dynamic>) vehicle = v; 
      } catch (_) {}
    }

    if (policy["provider_id"] != null) {
      try {
        provider = await ProviderService.getProviderDetails(policy["provider_id"].toString());
      } catch (_) {}
    }

    enriched.add({
      ...policy,
      "vehicle": vehicle,
      "provider": provider,
    });
  }

  return enriched;
}
}
