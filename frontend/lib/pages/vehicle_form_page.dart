import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:car_platform/services/vehicle_service.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();

  // car make -> list of models (loaded from assets/car_models.json)
  Map<String, List<String>> carData = {};

  // Fields
  String _make = "";
  String _model = "";
  String _plate = "";
  int _mileage = 0;
  int _yom = DateTime.now().year;
  String _fuelType = "Petrol";
  String? _transmission;
  String? _color;

  bool _loading = false;

  final List<String> _fuelTypes = ["Petrol", "Diesel", "Hybrid", "Electric"];
  final List<String> _transmissions = ["Automatic", "Manual"];
  final List<String> _colors = [
    "Black", "White", "Silver", "Blue", "Red", "Grey", "Green", "Other"
  ];

  // Hold references to the underlying controllers created by Autocomplete so we can clear them
  TextEditingController? _makeFieldController;
  TextEditingController? _modelFieldController;

  @override
  void initState() {
    super.initState();
    _loadCarData();
  }

  Future<void> _loadCarData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/car_models.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        carData = data.map((key, value) => MapEntry(key, List<String>.from(value)));
      });
    } catch (e) {
      debugPrint('Could not load car_models.json: $e');
      // app still works — Autocomplete will just have no suggestions
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    final res = await VehicleService.addVehicle({
      "make": _make,
      "model": _model,
      "plate": _plate,
      "mileage": _mileage,
      "yom": _yom,
      "fuel_type": _fuelType,
      "transmission": _transmission,
      "color": _color,
    });

    setState(() => _loading = false);

    if (res != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add vehicle")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Vehicle")),
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
                      return carData.keys;
                    }
                    final lower = textEditingValue.text.toLowerCase();
                    return carData.keys.where((k) => k.toLowerCase().contains(lower));
                  },
                  onSelected: (selection) {
                    setState(() {
                      _make = selection;
                      // clear model when make changes
                      _model = "";
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
                      onSaved: (val) => _make = val!.trim(),
                      onChanged: (val) {
                        // while typing a make, update _make and clear model suggestions/text
                        if (_make != val) {
                          setState(() {
                            _make = val;
                            _model = "";
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

                // === Plate ===
                TextFormField(
                  decoration: const InputDecoration(labelText: "Plate"),
                  onSaved: (val) => _plate = val!.trim().toUpperCase(),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? "Enter vehicle plate" : null,
                ),
                const SizedBox(height: 24),

                // === Mileage ===
                TextFormField(
                  decoration: const InputDecoration(labelText: "Mileage (km)"),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => _mileage = int.tryParse(val!.trim()) ?? 0,
                  validator: (val) {
                    final mileage = int.tryParse(val ?? "");
                    if (mileage == null || mileage < 0) {
                      return "Enter valid mileage";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // === Year of Manufacture ===
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "Year of Manufacture"),
                  keyboardType: TextInputType.number,
                  initialValue: DateTime.now().year.toString(),
                  onSaved: (val) =>
                      _yom = int.tryParse(val!.trim()) ?? DateTime.now().year,
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
                  value: _fuelType,
                  decoration: const InputDecoration(labelText: "Fuel Type"),
                  items: _fuelTypes
                      .map((ft) => DropdownMenuItem(value: ft, child: Text(ft)))
                      .toList(),
                  onChanged: (val) => setState(() => _fuelType = val!),
                ),
                const SizedBox(height: 24),

                // === Transmission ===
                DropdownButtonFormField<String>(
                  value: _transmission,
                  decoration: const InputDecoration(labelText: "Transmission"),
                  items: _transmissions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _transmission = val),
                  validator: (val) => val == null ? "Select transmission" : null,
                ),
                const SizedBox(height: 24),

                // === Color ===
                DropdownButtonFormField<String>(
                  value: _color,
                  decoration: const InputDecoration(labelText: "Color"),
                  items: _colors
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _color = val),
                  validator: (val) => val == null ? "Select color" : null,
                ),
                const SizedBox(height: 40),

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
                            "Save Vehicle",
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
