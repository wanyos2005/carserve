import 'package:flutter/material.dart';
import 'package:car_platform/components/modal_bottom_sheet.dart';

class EnhancedServiceSelector extends StatefulWidget {
  final List<Map<String, dynamic>> allServices;
  final List<Map<String, dynamic>> selectedServices;
  final Function(List<Map<String, dynamic>>) onConfirm;
  final bool isSparePartsMode;
  final bool isPurchaseMode;

  const EnhancedServiceSelector({
    super.key,
    required this.allServices,
    required this.selectedServices,
    required this.onConfirm,
    this.isSparePartsMode = false,
    this.isPurchaseMode = false,
  });

  @override
  State<EnhancedServiceSelector> createState() => _EnhancedServiceSelectorState();
}

class _EnhancedServiceSelectorState extends State<EnhancedServiceSelector> {
  List<Map<String, dynamic>> _selectedServices = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _showOnlySelected = false;
  String? _selectedRecommendedService; // Track which recommended service is selected
  
  // Recommended services data
  List<Map<String, dynamic>> get _recommendedServices {
    if (widget.isSparePartsMode) {
      return [
        {
          'name': 'Oil & Filters',
          'icon': Icons.oil_barrel,
          'color': Colors.orange,
          'keywords': ['oil', 'filter', 'lubrication', 'engine oil', 'motor oil'],
        },
        {
          'name': 'Brake Parts',
          'icon': Icons.car_repair,
          'color': Colors.red,
          'keywords': ['brake', 'brakes', 'pad', 'disc', 'rotor'],
        },
        {
          'name': 'Tire & Wheels',
          'icon': Icons.tire_repair,
          'color': Colors.blue,
          'keywords': ['tire', 'tyre', 'wheel', 'rim', 'tire'],
        },
        {
          'name': 'Engine Parts',
          'icon': Icons.engineering,
          'color': Colors.green,
          'keywords': ['engine', 'motor', 'spark plug', 'belt', 'gasket'],
        },
        {
          'name': 'AC Parts',
          'icon': Icons.ac_unit,
          'color': Colors.cyan,
          'keywords': ['ac', 'air conditioning', 'compressor', 'condenser', 'filter'],
        },
        {
          'name': 'Insurance',
          'icon': Icons.security,
          'color': Colors.green,
          'keywords': ['insurance', 'policy', 'coverage', 'premium', 'claim'],
          'isSpecial': true, // Flag for special handling
        },
      ];
    } else {
      return [
        {
          'name': 'Oil & Lubrication',
          'icon': Icons.oil_barrel,
          'color': Colors.orange,
          'keywords': ['oil', 'lubrication', 'lube', 'engine oil', 'motor oil'],
        },
        {
          'name': 'Brake Service',
          'icon': Icons.car_repair,
          'color': Colors.red,
          'keywords': ['brake', 'brakes', 'braking', 'disc', 'pad'],
        },
        {
          'name': 'Tire Service',
          'icon': Icons.tire_repair,
          'color': Colors.blue,
          'keywords': ['tire', 'tyre', 'wheel', 'alignment', 'balancing'],
        },
        {
          'name': 'Engine Service',
          'icon': Icons.engineering,
          'color': Colors.green,
          'keywords': ['engine', 'motor', 'tune', 'diagnostic', 'repair'],
        },
        {
          'name': 'AC Service',
          'icon': Icons.ac_unit,
          'color': Colors.cyan,
          'keywords': ['ac', 'air conditioning', 'cooling', 'refrigerant', 'climate'],
        },
        {
          'name': 'Insurance',
          'icon': Icons.security,
          'color': Colors.green,
          'keywords': ['insurance', 'policy', 'coverage', 'premium', 'claim'],
          'isSpecial': true, // Flag for special handling
        },
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedServices = widget.selectedServices
        .map((s) => _normalizeServiceMap(Map<String, dynamic>.from(s)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get unique categories
    final categories = widget.allServices
        .map((s) => _extractCategoryName(s))
        .where((cat) => cat != null)
        .toSet()
        .toList()
      ..sort();

    // Filter services
    final filteredServices = _getFilteredServices();

    return ModalBottomSheet(
      title: '', // Remove title to save space
      subtitle: null, // Remove subtitle to save space
      heightPercentage: 1, // Increased height for recommended services
      content: Column(
        children: [
          // Recommended Services Section
          _buildRecommendedServices(),
          
          // Search and filters
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: widget.isPurchaseMode 
                        ? 'Search spare parts...'
                        : (widget.isSparePartsMode 
                            ? 'Search spare parts...' 
                            : 'Search services...'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      // Clear recommended service selection when manually searching
                      if (value.isNotEmpty) {
                        _selectedRecommendedService = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Category filter chips, cart, and toggle in same row
                Row(
                  children: [
                    // Category filter chips
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ...categories.map((category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCategoryChip(category!, category),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Cart icon with count
                    _buildCartSubtitle(),
                    const SizedBox(width: 8),
                    // Toggle for showing only selected
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _showOnlySelected,
                          onChanged: (value) {
                            setState(() {
                              _showOnlySelected = value ?? false;
                            });
                          },
                        ),
                        const Text('Selected only'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Services list
          Expanded(
            child: filteredServices.isEmpty
                ? Center(
                    child: Text(
                      widget.isPurchaseMode 
                          ? 'No spare parts found'
                          : (widget.isSparePartsMode 
                              ? 'No spare parts found' 
                              : 'No services found'),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = _normalizeServiceMap(filteredServices[index]);
                      final isSelected = _selectedServices.any((s) => s['id'] == service['id']);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.green : Colors.blue,
                            child: Icon(
                              isSelected 
                                  ? Icons.check 
                                  : (widget.isPurchaseMode || widget.isSparePartsMode 
                                      ? Icons.inventory_2 
                                      : Icons.build),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            service['name'] ?? 'Unnamed Service',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_extractCategoryName(service) != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _extractCategoryName(service)!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              if (service['description'] != null)
                                Text(
                                  service['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: isSelected
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeService(service),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => _addService(service),
                                ),
                          onTap: () {
                            if (isSelected) {
                              _removeService(service);
                            } else {
                              _addService(service);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      footer: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: 16,
        ),
        child: Row(
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
                onPressed: _selectedServices.isNotEmpty
                    ? () {
                        widget.onConfirm(_selectedServices);
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  'Confirm (${_selectedServices.length})',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
          // Clear recommended service selection when using category filter
          _selectedRecommendedService = null;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[800],
    );
  }

  List<Map<String, dynamic>> _getFilteredServices() {
    var services = widget.allServices
        .map((s) => _normalizeServiceMap(Map<String, dynamic>.from(s)))
        .toList();

    // Filter by category (only if a specific category is selected)
    if (_selectedCategory.isNotEmpty) {
      services = services
          .where((s) => _extractCategoryName(s) == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      services = services.where((s) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        final description = (s['description'] ?? '').toString().toLowerCase();
        final category = (_extractCategoryName(s) ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        // Check basic fields
        bool basicMatch = name.contains(query) || 
                         description.contains(query) || 
                         category.contains(query);
        
        // Check requirements fields for additional matches
        bool requirementsMatch = false;
        final req = s['requirements'] ?? s['service_requirements'];
        if (req != null && req['fields'] != null) {
          final fields = req['fields'] as List<dynamic>?;
          if (fields != null) {
            for (var field in fields) {
              if (field is Map<String, dynamic>) {
                // Check field name
                final fieldName = (field['name'] ?? '').toString().toLowerCase();
                if (fieldName.contains(query)) {
                  requirementsMatch = true;
                  break;
                }
                
                // Check field label
                final fieldLabel = (field['label'] ?? '').toString().toLowerCase();
                if (fieldLabel.contains(query)) {
                  requirementsMatch = true;
                  break;
                }
                
                // Check field options
                final options = field['options'] as List<dynamic>?;
                if (options != null) {
                  for (var option in options) {
                    final optionStr = option.toString().toLowerCase();
                    if (optionStr.contains(query)) {
                      requirementsMatch = true;
                      break;
                    }
                  }
                }
              }
            }
          }
        }
        
        return basicMatch || requirementsMatch;
      }).toList();
    }

    // Filter by selected only
    if (_showOnlySelected) {
      services = services
          .where((s) => _selectedServices.any((selected) => selected['id'] == s['id']))
          .toList();
    }

    // Sort: selected first, then by name
    services.sort((a, b) {
      final aSelected = _selectedServices.any((s) => s['id'] == a['id']);
      final bSelected = _selectedServices.any((s) => s['id'] == b['id']);
      
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      
      final nameA = a['name'] ?? '';
      final nameB = b['name'] ?? '';
      return nameA.compareTo(nameB);
    });

    return services;
  }

  void _addService(Map<String, dynamic> service) {
    final normalized = _normalizeServiceMap(service);
    setState(() {
      _selectedServices.add(normalized);
    });
  }

  void _removeService(Map<String, dynamic> service) {
    final normalized = _normalizeServiceMap(service);
    setState(() {
      _selectedServices.removeWhere((s) => s['id'] == normalized['id']);
    });
  }

  Widget _buildRecommendedServices() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isPurchaseMode 
                ? 'Popular Parts' 
                : (widget.isSparePartsMode ? 'Popular Parts' : 'Popular Services'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // First row - 2 services
                Row(
                  children: [
                    Expanded(
                      child: _buildRecommendedPill(_recommendedServices[0]),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRecommendedPill(_recommendedServices[1]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Second row - 2 services
                Row(
                  children: [
                    Expanded(
                      child: _buildRecommendedPill(_recommendedServices[2]),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRecommendedPill(_recommendedServices[3]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Third row - 2 services
                Row(
                  children: [
                    Expanded(
                      child: _buildRecommendedPill(_recommendedServices[4]),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRecommendedPill(_recommendedServices[5]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedPill(Map<String, dynamic> recommended) {
    final isSelected = _selectedRecommendedService == recommended['name'];
    
    return InkWell(
      onTap: () => _filterByRecommended(recommended),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? recommended['color'].withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? recommended['color'] : recommended['color'].withOpacity(0.3),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? recommended['color'].withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              recommended['icon'],
              color: isSelected ? recommended['color'] : recommended['color'],
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                recommended['name'],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? recommended['color'] : recommended['color'],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterByRecommended(Map<String, dynamic> recommended) {
    // Special handling for insurance - redirect to marketplace
    if (recommended['isSpecial'] == true && recommended['name'] == 'Insurance') {
      Navigator.pushNamed(context, '/insurance/marketplace');
      return;
    }
    
    setState(() {
      // Set search query to the first keyword of the recommended service
      _searchQuery = recommended['keywords'][0];
      _selectedCategory = ''; // Reset category filter
      _showOnlySelected = false; // Reset selected filter
      _selectedRecommendedService = recommended['name']; // Track selected recommended service
    });
  }

  // --- Normalization helpers ---
  Map<String, dynamic> _normalizeServiceMap(Map<String, dynamic> s) {
    final id = s['id'] ?? s['service_id'];
    final name = s['name'] ?? s['service_name'];
    final description = s['description'] ?? s['service_description'];
    final categoryName = s['category']?['name'] ?? s['service_category_name'];
    final requirements = s['requirements'] ?? s['service_requirements'] ?? {};
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': {'name': categoryName},
      'requirements': requirements,
      // keep any extra fields
      ...s,
    };
  }

  String? _extractCategoryName(Map<String, dynamic> s) {
    final cat = s['category'];
    if (cat is Map && cat['name'] is String) return cat['name'] as String;
    if (s['service_category_name'] is String) return s['service_category_name'] as String;
    return null;
  }

  Widget _buildCartSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _selectedServices.isNotEmpty ? Colors.blue[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart,
            color: _selectedServices.isNotEmpty ? Colors.blue[700] : Colors.grey[600],
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${_selectedServices.length}',
            style: TextStyle(
              color: _selectedServices.isNotEmpty ? Colors.blue[700] : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}