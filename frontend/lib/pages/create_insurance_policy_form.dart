import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:car_platform/services/vehicle_service.dart';
import 'package:car_platform/services/insurance_policy_service.dart';

class InsurancePolicyFormPage extends StatefulWidget {
  const InsurancePolicyFormPage({super.key});

  @override
  State<InsurancePolicyFormPage> createState() => _InsurancePolicyFormPageState();
}

class _InsurancePolicyFormPageState extends State<InsurancePolicyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final InsurancePolicyService insurancePolicyService = InsurancePolicyService();
  late Future<List<dynamic>> _vehiclesData;

  // car make -> list of models (loaded from assets/car_models.json)
  Map<String, List<String>> insuranceCompaniesData= {};

  // Fields
  String _vehicle_id = "";
  String _insurance_type = "";
  String _insurer_id = "";
  int _commencement_date =  DateTime.now().year;
  int _expiry_date = DateTime.now().year;
 

  bool _loading = false;

  final List<String> _insuranceTypes = ["TPO", "Comprehensive"];


  // Hold references to the underlying controllers created by Autocomplete so we can clear them
  TextEditingController? _makeFieldController;
  TextEditingController? _modelFieldController;

  @override
  void initState() {
    super.initState();
    _loadInsuranceCompanies();
     _vehiclesData = insurancePolicyService.fetchVehicles();
  }
  

  Future<void> _loadInsuranceCompanies() async {
    try {
      final jsonString = await rootBundle.loadString('assets/insurance_companies.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        insuranceCompaniesData = data.map((key, value) => MapEntry(key, List<String>.from(value)));
      });
    } catch (e) {
      debugPrint('Could not load insurance companies.json: $e');
      // app still works — Autocomplete will just have no suggestions
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    final res = await InsurancePolicyService.addInsurancePolicy({
      
      "vehicle_id": _vehicle_id,
      "insurance_type": _insurance_type,
      "insurer_id": _insurer_id,
      "commencement_date": _commencement_date,
      "expiry_date": _expiry_date,
      
    });

    setState(() => _loading = false);

    if (res != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add record")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Policy Details")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // === MAKE (Autocomplete) ===
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      // show all makes as suggestions when typing, else empty
                      return insuranceCompaniesData.keys;
                    }
                    final lower = textEditingValue.text.toLowerCase();
                    return insuranceCompaniesData.keys.where((k) => k.toLowerCase().contains(lower));
                  },
                  onSelected: (selection) {
                    setState(() {
                      _insurer_id = selection;
                      // clear model when make changes
                      _insurer_id = "";
                      _modelFieldController?.clear();
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // keep controller reference so we can clear it when make changes
                    _makeFieldController = controller;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: "Make"),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? "Enter vehicle make" : null,
                      onSaved: (val) => _insurer_id = val!.trim(),
                      onChanged: (val) {
                        // while typing a make, update _make and clear model suggestions/text
                        if (_insurer_id != val) {
                          setState(() {
                            _insurer_id = val;
                            // _model = "";
                            _modelFieldController?.clear();
                          });
                        }
                      },
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // === MODEL (Autocomplete filtered by make) ===
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query = textEditingValue.text;
                    if (query.isEmpty) return const Iterable<String>.empty();

                    // find models for exact make key if available, otherwise try fuzzy match of makes
                    List<String> candidates = [];
                    if (carData.containsKey(_make)) {
                      candidates = carData[_make]!;
                    } else {
                      final matches = carData.keys
                          .where((k) => k.toLowerCase().contains(_make.toLowerCase()))
                          .toList();
                      for (var k in matches) {
                        candidates.addAll(carData[k]!);
                      }
                    }

                    // if still empty (no make match), fallback to all models (optional)
                    if (candidates.isEmpty) {
                      candidates = carData.values.expand((v) => v).toList();
                    }

                    final lower = query.toLowerCase();
                    return candidates.where((m) => m.toLowerCase().contains(lower));
                  },
                  onSelected: (selection) {
                    setState(() => _model = selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    _modelFieldController = controller;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: "Model"),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? "Enter vehicle model" : null,
                      onSaved: (val) => _model = val!.trim(),
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // === Commencement Date ===
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "Commencement Date"),
                  keyboardType: TextInputType.number,
                  initialValue: DateTime.now().year.toString(),
                  onSaved: (val) =>
                      _commencement_date = int.tryParse(val!.trim()) ?? DateTime.now().year,
                  validator: (val) {
                    final year = int.tryParse(val ?? "");
                    if (year == null ||
                        year < 1900 ||
                        year > DateTime.now().year) {
                      return "Enter a valid year";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

    // === Expiry Date ===
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "Expiry Date"),
                  keyboardType: TextInputType.number,
                  initialValue: DateTime.now().year.toString(),
                  onSaved: (val) =>
                      _expiry_date = int.tryParse(val!.trim()) ?? DateTime.now().year,
                  validator: (val) {
                    final year = int.tryParse(val ?? "");
                    if (year == null ||
                        year < 1900 ||
                        year > DateTime.now().year) {
                      return "Enter a valid year";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // === Fuel Type ===
                DropdownButtonFormField<String>(
                  value: _insurance_type,
                  decoration: const InputDecoration(labelText: "Insurance Type"),
                  items: _insuranceTypes
                      .map((ft) => DropdownMenuItem(value: ft, child: Text(ft)))
                      .toList(),
                  onChanged: (val) => setState(() => _fuelType = val!),
                ),
                const SizedBox(height: 24),

               
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor:
                                theme.colorScheme.primary, // theme-driven
                            foregroundColor:
                                theme.colorScheme.onPrimary, // text color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Save Details",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
