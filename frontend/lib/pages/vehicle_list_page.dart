// lib/pages/vehicle_list_page.dart
import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/vehicle_service.dart';
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

  Future<void> _refreshVehicles() async {
    await _fetchVehicles();
  }

  /// Opens the dedicated VehicleFormPage to add a new vehicle.
  /// Refreshes the list if a vehicle was successfully added.
  void _openAddVehicleForm() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VehicleFormPage()),
    );
    // Refresh the list if a vehicle was successfully added
    if (added == true) _fetchVehicles();
  }

  /// Deletes a vehicle after confirmation.
  /// Shows a confirmation dialog and refreshes the list if successful.
  Future<void> _deleteVehicle(dynamic vehicle) async {
    final vehicleId = vehicle['id']?.toString();
    if (vehicleId == null || vehicleId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete: Vehicle ID not found')),
        );
      }
      return;
    }

    final make = vehicle['make'] ?? 'Unknown';
    final model = vehicle['model'] ?? '';
    final plate = vehicle['plate'] ?? 'N/A';
    final vehicleName = "${make} ${model}".trim();
    final vehicleInfo = plate != 'N/A' ? "$vehicleName ($plate)" : vehicleName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete "$vehicleInfo"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _loading = true);
        final success = await VehicleService.deleteVehicle(vehicleId);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehicle "$vehicleInfo" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchVehicles();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete vehicle'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _loading = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting vehicle: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _loading = false);
        }
      }
    }
  }

  Color _getFuelTypeColor(String? fuelType) {
    switch (fuelType?.toLowerCase()) {
      case 'electric':
        return Colors.green;
      case 'hybrid':
        return Colors.teal;
      case 'diesel':
        return Colors.orange;
      case 'petrol':
      default:
        return Colors.blue;
    }
  }

  Color _getDarkerColor(Color color) {
    // Return a darker shade of the color
    return Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
  }

  IconData _getFuelTypeIcon(String? fuelType) {
    switch (fuelType?.toLowerCase()) {
      case 'electric':
        return Icons.electric_bolt;
      case 'hybrid':
        return Icons.ev_station;
      case 'diesel':
        return Icons.local_gas_station;
      case 'petrol':
      default:
        return Icons.local_gas_station;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    // Theme-aware gradient that adapts to dark mode
    final gradientColors = isDark
        ? [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ]
        : [
            Colors.purple[50]!,
            Colors.blue[50]!,
            Colors.cyan[50]!,
          ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: theme.iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Vehicles",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_vehicles.isNotEmpty)
                            Text(
                              "${_vehicles.length} vehicle${_vehicles.length > 1 ? 's' : ''}",
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshVehicles,
                      color: theme.colorScheme.primary,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
          : _vehicles.isEmpty
                        ? _buildEmptyState(theme)
                        : RefreshIndicator(
                            onRefresh: _refreshVehicles,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final v = _vehicles[index];
                                return _buildVehicleCard(v, theme, index);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddVehicleForm,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Vehicle",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 80,
                color: theme.iconTheme.color?.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "No Vehicles Yet",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Add your first vehicle to start tracking\nyour car's maintenance and services",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openAddVehicleForm,
              icon: const Icon(Icons.add),
              label: const Text("Add Your First Vehicle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(dynamic vehicle, ThemeData theme, int index) {
    final make = vehicle['make'] ?? 'Unknown';
    final model = vehicle['model'] ?? '';
    final plate = vehicle['plate'] ?? 'N/A';
    final mileage = vehicle['mileage'] ?? 0;
    final yom = vehicle['yom'] ?? 'N/A';
    final fuelType = vehicle['fuel_type'] ?? 'Petrol';
    final color = vehicle['color'] ?? '';
    final transmission = vehicle['transmission'] ?? '';

    return _VehicleCard(
      vehicle: vehicle,
      make: make,
      model: model,
      plate: plate,
      mileage: mileage,
      yom: yom,
      fuelType: fuelType,
      color: color,
      transmission: transmission,
      theme: theme,
      getFuelTypeColor: _getFuelTypeColor,
      getFuelTypeIcon: _getFuelTypeIcon,
      getDarkerColor: _getDarkerColor,
      onDelete: _deleteVehicle,
    );
  }

}

/// Expandable vehicle card widget - shows basic info by default, detailed info when expanded
class _VehicleCard extends StatefulWidget {
  final dynamic vehicle;
  final String make;
  final String model;
  final String plate;
  final int mileage;
  final dynamic yom;
  final String fuelType;
  final String color;
  final String transmission;
  final ThemeData theme;
  final Color Function(String?) getFuelTypeColor;
  final IconData Function(String?) getFuelTypeIcon;
  final Color Function(Color) getDarkerColor;
  final Future<void> Function(dynamic) onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.make,
    required this.model,
    required this.plate,
    required this.mileage,
    required this.yom,
    required this.fuelType,
    required this.color,
    required this.transmission,
    required this.theme,
    required this.getFuelTypeColor,
    required this.getFuelTypeIcon,
    required this.getDarkerColor,
    required this.onDelete,
  });

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final fuelColor = widget.getFuelTypeColor(widget.fuelType);
    final fuelIcon = widget.getFuelTypeIcon(widget.fuelType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Column(
            children: [
              // Always visible - basic info (like home page)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Vehicle Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: isDark ? Colors.blue[300] : Colors.blue[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Vehicle Name and Plate
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.make} ${widget.model}".trim(),
                            style: widget.theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Plate: ${widget.plate}",
                            style: widget.theme.textTheme.bodySmall,
                          ),
                          if (widget.mileage > 0)
                            Text(
                              "Mileage: ${widget.mileage} km",
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Expand/Collapse Icon
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: widget.theme.iconTheme.color?.withOpacity(0.6),
                    ),
                  ],
                ),
              ),

              // Expandable section - detailed info
              if (_isExpanded) ...[
                Divider(
                  height: 1,
                  color: widget.theme.dividerColor.withOpacity(0.5),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Details Row
                      Row(
                        children: [
                          // Mileage
                          Expanded(
                            child: _buildDetailChip(
                              icon: Icons.speed,
                              label: 'Mileage',
                              value: '${widget.mileage.toString()} km',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Fuel Type
                          Expanded(
                            child: _buildDetailChip(
                              icon: fuelIcon,
                              label: 'Fuel',
                              value: widget.fuelType,
                              color: fuelColor,
                            ),
                          ),
                        ],
                      ),
                      if (widget.yom != null && widget.yom != 'N/A') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Year
                            Expanded(
                              child: _buildDetailChip(
                                icon: Icons.calendar_today,
                                label: 'Year',
                                value: widget.yom.toString(),
                                color: Colors.purple,
                              ),
                            ),
                            if (widget.transmission.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDetailChip(
                                  icon: Icons.settings,
                                  label: 'Transmission',
                                  value: widget.transmission,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (widget.color.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailBadge(
                          icon: Icons.palette,
                          text: widget.color,
                          color: Colors.pink,
                        ),
                      ],
                      // Delete button
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => widget.onDelete(widget.vehicle),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text('Delete Vehicle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = widget.theme.brightness == Brightness.dark;
    final opacity = isDark ? 0.2 : 0.1;
    final borderOpacity = isDark ? 0.4 : 0.3;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(borderOpacity),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: widget.getDarkerColor(color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final isDark = widget.theme.brightness == Brightness.dark;
    final opacity = isDark ? 0.2 : 0.1;
    final borderOpacity = isDark ? 0.4 : 0.3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(borderOpacity),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: widget.getDarkerColor(color),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
