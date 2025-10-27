import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/expenses_service.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/services/vehicle_service.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  String? _vehicleId;
  String _type = 'service';
  String? _location;
  int? _cost;
  List<dynamic> _vehicles = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vehicles = await VehicleService.listVehicles();
    setState(() => _vehicles = vehicles);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final userIdStr = UserContextService.currentContext?.id;
    final userId = userIdStr != null ? int.tryParse(userIdStr) : null;
    if (userId == null) return;
    try {
      await ExpensesService.createExpense(
        ownerId: userId,
        vehicleId: _vehicleId!,
        expenseType: _type,
        location: _location,
        cost: _cost!,
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Vehicle'),
                items: _vehicles.map<DropdownMenuItem<String>>((v) => DropdownMenuItem<String>(
                  value: v['id'].toString(),
                  child: Text("${v['plate'] ?? ''} ${v['make'] ?? ''}"),
                )).toList(),
                onChanged: (v) => setState(() => _vehicleId = v),
                validator: (v) => v == null ? 'Select vehicle' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'service', child: Text('Service')),
                  DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                  DropdownMenuItem(value: 'parking', child: Text('Parking')),
                  DropdownMenuItem(value: 'toll', child: Text('Toll')),
                  DropdownMenuItem(value: 'insurance', child: Text('Insurance')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'service'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location / Note'),
                onChanged: (v) => _location = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Cost (KES)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter amount' : null,
                onChanged: (v) => _cost = int.tryParse(v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


