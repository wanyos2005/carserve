import 'package:flutter/material.dart';
import 'package:car_platform/services/vehicle_service.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();

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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.blue, width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to add vehicle")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Vehicle")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: _inputDecoration("Make"),
                  onSaved: (val) => _make = val!.trim(),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? "Enter vehicle make" : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: _inputDecoration("Model"),
                  onSaved: (val) => _model = val!.trim(),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? "Enter vehicle model" : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: _inputDecoration("Plate"),
                  onSaved: (val) => _plate = val!.trim().toUpperCase(),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? "Enter vehicle plate" : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: _inputDecoration("Mileage (km)"),
                  keyboardType: TextInputType.number,
                  onSaved: (val) =>
                      _mileage = int.tryParse(val!.trim()) ?? 0,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: _inputDecoration("Year of Manufacture"),
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
                DropdownButtonFormField<String>(
                  value: _fuelType,
                  decoration: _inputDecoration("Fuel Type"),
                  items: _fuelTypes
                      .map((ft) =>
                          DropdownMenuItem(value: ft, child: Text(ft)))
                      .toList(),
                  onChanged: (val) => setState(() => _fuelType = val!),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _transmission,
                  decoration: _inputDecoration("Transmission"),
                  items: _transmissions
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _transmission = val),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _color,
                  decoration: _inputDecoration("Color"),
                  items: _colors
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _color = val),
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
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Save Vehicle",
                            style: TextStyle(fontSize: 16, color: Colors.white),
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
