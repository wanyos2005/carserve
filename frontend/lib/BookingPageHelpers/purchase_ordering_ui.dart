import 'package:flutter/material.dart';
import 'package:car_platform/services/provider_service.dart';
import 'package:car_platform/services/global_service_api.dart';

class PurchaseOrderingUI extends StatefulWidget {
  final List<dynamic> vehicles;
  final String? selectedVehicleId;
  final Map<String, dynamic>? me;
  final Function(String?) onVehicleChanged;
  final VoidCallback onPurchase;

  const PurchaseOrderingUI({
    super.key,
    required this.vehicles,
    required this.selectedVehicleId,
    required this.me,
    required this.onVehicleChanged,
    required this.onPurchase,
  });

  @override
  State<PurchaseOrderingUI> createState() => _PurchaseOrderingUIState();
}

class _PurchaseOrderingUIState extends State<PurchaseOrderingUI> {
  // Purchase-specific state
  List<Map<String, dynamic>> _selectedParts = [];
  List<Map<String, dynamic>> _allParts = [];
  Map<String, dynamic>? _selectedSupplier;
  List<Map<String, dynamic>> _matchedSuppliers = [];
  
  // Purchase details
  String _purchaseType = 'inquiry'; // 'inquiry', 'quote', 'order'
  String _urgency = 'normal'; // 'urgent', 'normal', 'flexible'
  String _deliveryPreference = 'pickup'; // 'pickup', 'delivery'
  
  // Loading states
  bool _loadingSuppliers = false;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    try {
      // Load parts from global services (filtered for spare parts)
      final services = await GlobalServiceApi.getAllGlobalServices();
      _allParts = services
          .where((s) => s['category']?['name']?.toLowerCase().contains('part') == true ||
                      s['name']?.toLowerCase().contains('part') == true ||
                      s['description']?.toLowerCase().contains('part') == true)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint("Error loading parts: $e");
    }
  }

  Future<void> _fetchMatchedSuppliers() async {
    if (_selectedParts.isEmpty) return;

    setState(() {
      _loadingSuppliers = true;
      _matchedSuppliers = [];
      _selectedSupplier = null;
    });

    try {
      final partIds = _selectedParts.map((p) => p["id"].toString()).toList();
      final queryString = partIds.map((id) => "service_ids=$id").join("&");
      final url = "/service-providers/providers/?$queryString&match_all=true";
      final filtered = await ProviderService.getProvidersByUrl(url);

      setState(() {
        _matchedSuppliers = filtered.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint("Failed to fetch suppliers: $e");
    } finally {
      setState(() => _loadingSuppliers = false);
    }
  }

  Future<void> _showPartsSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PartsSelectorModal(
        allParts: _allParts,
        selectedParts: _selectedParts,
        onConfirm: (parts) async {
          setState(() => _selectedParts = parts);
          await _fetchMatchedSuppliers();
        },
      ),
    );
  }

  Future<void> _showSupplierSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SupplierSelectorModal(
        suppliers: _matchedSuppliers,
        selectedSupplier: _selectedSupplier,
        onSelect: (supplier) => setState(() => _selectedSupplier = supplier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Vehicle Selection
          DropdownButtonFormField<String>(
            value: widget.selectedVehicleId,
            items: widget.vehicles
                .map((v) => DropdownMenuItem<String>(
                      value: v["id"].toString(),
                      child: Text("${v["plate"] ?? ""} ${v["make"] ?? ""} (${v["model"] ?? v["id"]})"),
                    ))
                .toList(),
            onChanged: widget.onVehicleChanged,
            decoration: const InputDecoration(
              labelText: "Select Vehicle",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

        // Parts Selection
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.orange),
            title: const Text("Spare Parts"),
            subtitle: _selectedParts.isEmpty
                ? const Text("Tap to select parts")
                : Text("${_selectedParts.length} parts selected"),
            trailing: _selectedParts.isEmpty
                ? const Icon(Icons.arrow_forward_ios)
                : Chip(
                    label: Text("${_selectedParts.length}"),
                    backgroundColor: Colors.orange[100],
                  ),
            onTap: _showPartsSelector,
          ),
        ),
        const SizedBox(height: 12),

        // Show selected parts
        if (_selectedParts.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      "${_selectedParts.length} parts selected",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: _selectedParts.take(3).map((part) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      part["name"] ?? "Part",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[800],
                      ),
                    ),
                  )).toList()
                    ..addAll(_selectedParts.length > 3 ? [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "+${_selectedParts.length - 3} more",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ] : []),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Supplier Selection
        Card(
          child: ListTile(
            leading: const Icon(Icons.store, color: Colors.green),
            title: const Text("Parts Supplier"),
            subtitle: _selectedSupplier == null
                ? Text(_loadingSuppliers
                    ? "Loading suppliers..."
                    : _matchedSuppliers.isEmpty
                        ? "No suppliers available"
                        : "Tap to select supplier")
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSupplier!["provider_name"] ?? "Selected Supplier",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedSupplier!["location"]?["area"] ?? "Nairobi",
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            trailing: _loadingSuppliers
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _selectedSupplier == null
                    ? const Icon(Icons.arrow_forward_ios)
                    : Chip(
                        label: Text(_selectedSupplier!["rating"]?.toString() ?? "0.0"),
                        backgroundColor: Colors.green[100],
                        avatar: const Icon(Icons.star, size: 16),
                      ),
            onTap: _matchedSuppliers.isEmpty ? null : _showSupplierSelector,
          ),
        ),
        const SizedBox(height: 16),

        // Purchase Type Selection
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Purchase Type",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                // Use Wrap for better responsive design
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 80) / 3, // Responsive width
                      child: _buildPurchaseTypeOption(
                        'inquiry',
                        'Inquiry',
                        Icons.help_outline,
                        'Ask about availability',
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 80) / 3,
                      child: _buildPurchaseTypeOption(
                        'quote',
                        'Quote',
                        Icons.request_quote,
                        'Request pricing',
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 80) / 3,
                      child: _buildPurchaseTypeOption(
                        'order',
                        'Order',
                        Icons.shopping_cart,
                        'Place order',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Urgency and Delivery Preferences
        LayoutBuilder(
          builder: (context, constraints) {
            // Use single column on small screens, row on larger screens
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Urgency",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _urgency,
                            items: const [
                              DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                              DropdownMenuItem(value: 'normal', child: Text('Normal')),
                              DropdownMenuItem(value: 'flexible', child: Text('Flexible')),
                            ],
                            onChanged: (value) => setState(() => _urgency = value!),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Delivery",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _deliveryPreference,
                            items: const [
                              DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                              DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                            ],
                            onChanged: (value) => setState(() => _deliveryPreference = value!),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Urgency",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _urgency,
                              items: const [
                                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                                DropdownMenuItem(value: 'flexible', child: Text('Flexible')),
                              ],
                              onChanged: (value) => setState(() => _urgency = value!),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Delivery",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _deliveryPreference,
                              items: const [
                                DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                                DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                              ],
                              onChanged: (value) => setState(() => _deliveryPreference = value!),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 12),

        // Notes
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Additional Notes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Any specific requirements or notes...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    // Store notes for future use
                    // _notes = value;
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Purchase Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedParts.isNotEmpty && _selectedSupplier != null
                ? widget.onPurchase
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _purchaseType == 'inquiry' ? 'Send Inquiry' :
              _purchaseType == 'quote' ? 'Request Quote' : 'Place Order',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20), // Add bottom padding for better scrolling
        ],
      ),
    );
  }

  Widget _buildPurchaseTypeOption(String value, String title, IconData icon, String subtitle) {
    final isSelected = _purchaseType == value;
    return InkWell(
      onTap: () => setState(() => _purchaseType = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange[300]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange[700] : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.orange[700] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Parts Selector Modal
class _PartsSelectorModal extends StatefulWidget {
  final List<Map<String, dynamic>> allParts;
  final List<Map<String, dynamic>> selectedParts;
  final Function(List<Map<String, dynamic>>) onConfirm;

  const _PartsSelectorModal({
    required this.allParts,
    required this.selectedParts,
    required this.onConfirm,
  });

  @override
  State<_PartsSelectorModal> createState() => _PartsSelectorModalState();
}

class _PartsSelectorModalState extends State<_PartsSelectorModal> {
  List<Map<String, dynamic>> _selectedParts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedParts = List.from(widget.selectedParts);
  }

  @override
  Widget build(BuildContext context) {
    final filteredParts = _searchQuery.isEmpty
        ? widget.allParts
        : widget.allParts.where((part) {
            final name = (part['name'] ?? '').toString().toLowerCase();
            final description = (part['description'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || description.contains(query);
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text(
                "Select Parts",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search parts...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),

          // Parts list
          Expanded(
            child: ListView.builder(
              itemCount: filteredParts.length,
              itemBuilder: (context, index) {
                final part = filteredParts[index];
                final isSelected = _selectedParts.any((p) => p['id'] == part['id']);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.orange : Colors.grey,
                      child: Icon(
                        isSelected ? Icons.check : Icons.inventory_2,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(part['name'] ?? 'Unnamed Part'),
                    subtitle: part['description'] != null
                        ? Text(part['description'])
                        : null,
                    trailing: isSelected
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removePart(part),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () => _addPart(part),
                          ),
                    onTap: () {
                      if (isSelected) {
                        _removePart(part);
                      } else {
                        _addPart(part);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Footer
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedParts.isNotEmpty
                      ? () {
                          widget.onConfirm(_selectedParts);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text('Confirm (${_selectedParts.length})'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addPart(Map<String, dynamic> part) {
    setState(() => _selectedParts.add(part));
  }

  void _removePart(Map<String, dynamic> part) {
    setState(() => _selectedParts.removeWhere((p) => p['id'] == part['id']));
  }
}

// Supplier Selector Modal
class _SupplierSelectorModal extends StatefulWidget {
  final List<Map<String, dynamic>> suppliers;
  final Map<String, dynamic>? selectedSupplier;
  final Function(Map<String, dynamic>) onSelect;

  const _SupplierSelectorModal({
    required this.suppliers,
    required this.selectedSupplier,
    required this.onSelect,
  });

  @override
  State<_SupplierSelectorModal> createState() => _SupplierSelectorModalState();
}

class _SupplierSelectorModalState extends State<_SupplierSelectorModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text(
                "Select Supplier",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Suppliers list
          Expanded(
            child: ListView.builder(
              itemCount: widget.suppliers.length,
              itemBuilder: (context, index) {
                final supplier = widget.suppliers[index];
                final isSelected = widget.selectedSupplier?['id'] == supplier['id'];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.green : Colors.blue,
                      child: Icon(
                        isSelected ? Icons.check : Icons.store,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(supplier['provider_name'] ?? 'Unnamed Supplier'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (supplier['location']?['area'] != null)
                          Text(supplier['location']['area']),
                        if (supplier['rating'] != null)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(supplier['rating'].toString()),
                            ],
                          ),
                      ],
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.radio_button_checked, color: Colors.green)
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () {
                      widget.onSelect(supplier);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
