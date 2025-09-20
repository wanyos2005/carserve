// lib/pages/vehicle_form_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/vehicle_service.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _make = "";
  String _model = "";
  String _plate = "";
  int _mileage = 0;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    final res = await VehicleService.addVehicle({
      "make": _make,
      "model": _model,
      "plate": _plate,
      "mileage": _mileage,
    });

    setState(() => _loading = false);

    if (res != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add vehicle")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Make"),
                onSaved: (val) => _make = val!.trim(),
                validator: (val) => (val == null || val.isEmpty) ? "Enter vehicle make" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Model"),
                onSaved: (val) => _model = val!.trim(),
                validator: (val) => (val == null || val.isEmpty) ? "Enter vehicle model" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Plate"),
                onSaved: (val) => _plate = val!.trim(),
                validator: (val) => (val == null || val.isEmpty) ? "Enter vehicle plate" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Mileage (km)"),
                keyboardType: TextInputType.number,
                onSaved: (val) => _mileage = int.tryParse(val!.trim()) ?? 0,
              ),
              const SizedBox(height: 20),
              _loading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _submit, child: const Text("Save Vehicle"))
            ],
          ),
        ),
      ),
    );
  }
}
