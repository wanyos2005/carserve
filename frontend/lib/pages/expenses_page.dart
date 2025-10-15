import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:car_platform/services/expenses_service.dart';
import 'package:car_platform/services/user_context_service.dart';
import 'package:car_platform/services/vehicle_service.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  bool _loading = true;
  List<dynamic> _expenses = [];
  Map<String, dynamic> _stats = const {'total': 0, 'count': 0};
  String? _vehicleId;
  List<dynamic> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final vehicles = await VehicleService.listVehicles();
    setState(() { _vehicles = vehicles; });
    await _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    final userIdStr = UserContextService.currentContext?.id;
    final userId = userIdStr != null ? int.tryParse(userIdStr) : null;
    if (userId == null) { setState(() { _loading = false; }); return; }

    setState(() => _loading = true);
    final items = await ExpensesService.listExpenses(ownerId: userId, vehicleId: _vehicleId);
    final stats = await ExpensesService.getStats(ownerId: userId, vehicleId: _vehicleId);
    setState(() {
      _expenses = items;
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_KE', symbol: 'KSh ');
    return Scaffold(
      appBar: AppBar(title: const Text('Car Spending')),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Vehicle'),
                    items: _vehicles.map<DropdownMenuItem<String>>((v) => DropdownMenuItem<String>(
                      value: v['id'].toString(),
                      child: Text("${v['plate'] ?? ''} ${v['make'] ?? ''}"),
                    )).toList(),
                    onChanged: (val) { setState(() => _vehicleId = val); _load(refresh: true); },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/expenses/add').then((_) => _load(refresh: true)),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _kpiCard('Total', currency.format(_stats['total'] ?? 0)),
                const SizedBox(width: 12),
                _kpiCard('Count', (_stats['count'] ?? 0).toString()),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading)
              ..._expenses.map((e) => _ExpenseTile(expense: e)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final dynamic expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final type = (expense['expense_type'] ?? '').toString();
    final cost = expense['cost'] ?? 0;
    final location = (expense['location'] ?? '').toString();
    final createdAt = expense['created_at'];
    final created = createdAt != null ? DateTime.tryParse(createdAt.toString()) : null;
    final timeStr = created != null ? DateFormat.yMMMd().format(created) : '';

    IconData icon;
    Color color;
    switch (type) {
      case 'service': icon = Icons.build; color = Colors.blue; break;
      case 'fuel': icon = Icons.local_gas_station; color = Colors.orange; break;
      case 'parking': icon = Icons.local_parking; color = Colors.purple; break;
      case 'toll': icon = Icons.alt_route; color = Colors.teal; break;
      case 'insurance': icon = Icons.shield; color = Colors.indigo; break;
      default: icon = Icons.receipt_long; color = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(type.toUpperCase()),
      subtitle: Text(location.isNotEmpty ? location : timeStr),
      trailing: Text('KSh $cost', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}


