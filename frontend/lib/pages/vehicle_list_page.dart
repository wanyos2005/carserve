// lib/pages/vehicle_list_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/vehicle_service.dart';
import 'vehicle_form_page.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  List<dynamic> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _loading = true);
    final res = await VehicleService.listVehicles();
    setState(() {
      _vehicles = res;
      _loading = false;
    });
  }

  void _openAddVehicleForm() async {
    final added = await Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleFormPage()));
    if (added == true) _fetchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Vehicles")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text("No vehicles found."))
              : ListView.builder(
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final v = _vehicles[index];
                    return ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text("${v['make']} ${v['model']}"),
                      subtitle: Text("Plate: ${v['plate']} | Mileage: ${v['mileage']} km"),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddVehicleForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
