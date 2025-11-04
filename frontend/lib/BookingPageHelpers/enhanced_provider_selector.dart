import 'package:flutter/material.dart';
import 'package:driveon_car_platform/components/modal_bottom_sheet.dart';
import 'package:driveon_car_platform/services/provider_service.dart';


class EnhancedProviderSelector extends StatefulWidget {
  final List<Map<String, dynamic>> filteredProviders;
  final List<Map<String, dynamic>> selectedServices;
  final bool recommendedOnly;
  final Map<String, dynamic>? selectedProvider;
  final Function(Map<String, dynamic>) onSelect;
  final Map<String, dynamic>? customerLocation;

  const EnhancedProviderSelector({
    super.key,
    required this.filteredProviders,
    required this.selectedServices,
    required this.recommendedOnly,
    required this.selectedProvider,
    required this.onSelect,
    this.customerLocation,
  });

  @override
  State<EnhancedProviderSelector> createState() => _EnhancedProviderSelectorState();
}

class _EnhancedProviderSelectorState extends State<EnhancedProviderSelector> {
  String _sortBy = 'rating'; // rating, price, distance, name
  String _filterBy = 'all'; // all, registered, unregistered
  double _minRating = 0.0;
  String _selectedArea = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get unique areas for filtering
    final areas = widget.filteredProviders
        .map((p) => p['location']?['area'] as String?)
        .where((area) => area != null)
        .toSet()
        .toList()
      ..sort();

    // Apply filters and sorting
    final filteredAndSorted = _applyFiltersAndSorting(widget.filteredProviders);

    return ModalBottomSheet(
      title: 'Select Provider',
      subtitle: '${filteredAndSorted.length} providers',
      heightPercentage: 1, // Full screen height like enhanced_service_selector
      content: Column(
        children: [

              // Filter controls - More relaxed layout
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter & Sort Providers',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search providers...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Sort and filter row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sortBy,
                            decoration: const InputDecoration(
                              labelText: 'Sort by',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: [
                              const DropdownMenuItem(value: 'rating', child: Text('Rating')),
                              const DropdownMenuItem(value: 'price', child: Text('Price')),
                              const DropdownMenuItem(value: 'name', child: Text('Name')),
                              if (widget.customerLocation != null)
                                const DropdownMenuItem(value: 'distance', child: Text('Distance')),
                            ],
                            onChanged: (value) => setState(() => _sortBy = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filterBy,
                            decoration: const InputDecoration(
                              labelText: 'Filter',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(value: 'registered', child: Text('Registered')),
                              DropdownMenuItem(value: 'unregistered', child: Text('Unregistered')),
                            ],
                            onChanged: (value) => setState(() => _filterBy = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Area filter and rating filter row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedArea,
                            decoration: const InputDecoration(
                              labelText: 'Area',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('All Areas')),
                              ...areas.map((area) => DropdownMenuItem(value: area, child: Text(area!))),
                            ],
                            onChanged: (value) => setState(() => _selectedArea = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Min Rating: ${_minRating.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Slider(
                                value: _minRating,
                                min: 0.0,
                                max: 5.0,
                                divisions: 10,
                                onChanged: (value) => setState(() => _minRating = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Provider list
              Expanded(
                child: ListView.builder(
                  itemCount: filteredAndSorted.length + 1, // +1 for "Other" option
                  itemBuilder: (context, index) {
                    // "Other" option at the end
                    if (index == filteredAndSorted.length) {
                      final isOtherSelected = widget.selectedProvider?['is_manual'] == true;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: isOtherSelected ? Colors.blue[50] : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[600],
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                          title: Text(
                            'Other / Not Listed',
                            style: TextStyle(
                              fontWeight: isOtherSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            widget.selectedProvider != null && widget.selectedProvider!['is_manual'] == true
                                ? widget.selectedProvider!['provider_name'] ?? 'Enter provider name'
                                : 'Add a provider not in the list',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: widget.selectedProvider != null && widget.selectedProvider!['is_manual'] == true
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showManualProviderDialog(),
                        ),
                      );
                    }
                    
                    final provider = filteredAndSorted[index];
                    final isSelected = widget.selectedProvider?['provider_id'] == provider['provider_id'] &&
                                       widget.selectedProvider?['is_manual'] != true;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: isSelected ? Colors.blue[50] : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: provider['is_registered'] ? Colors.green : Colors.orange,
                          child: Text(
                            provider['provider_name']?.substring(0, 1).toUpperCase() ?? 'P',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          provider['provider_name'] ?? 'Unknown Provider',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider['location']?['area'] ?? 'Nairobi'),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                                Text(' ${provider['rating']?.toString() ?? '0.0'}'),
                                const SizedBox(width: 16),
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                Expanded(
                                  child: Text(
                                    ' ${provider['location']?['address'] ?? 'Nairobi, Kenya'}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (widget.customerLocation != null && provider['distance_display'] != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      provider['distance_display'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (provider['services'] != null)
                              Text(
                                '${provider['services'].length} services available',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (provider['is_registered'])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Verified',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _getPriceRange(provider),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () {
                          widget.onSelect(provider);
                          Navigator.pop(context);
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.selectedProvider != null
                ? () => Navigator.pop(context)
                : null,
            child: Text(
              widget.selectedProvider != null
                  ? 'Confirm ${widget.selectedProvider!['provider_name'] ?? widget.selectedProvider!['name'] ?? 'Provider'}'
                  : 'Select a Provider',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFiltersAndSorting(List<Map<String, dynamic>> providers) {
    var filtered = providers.where((provider) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final name = (provider['provider_name'] ?? '').toString().toLowerCase();
        final area = (provider['location']?['area'] ?? '').toString().toLowerCase();
        final address = (provider['location']?['address'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        if (!name.contains(query) && !area.contains(query) && !address.contains(query)) {
          return false;
        }
      }
      
      // Filter by registration status
      if (_filterBy == 'registered' && !provider['is_registered']) return false;
      if (_filterBy == 'unregistered' && provider['is_registered']) return false;
      
      // Filter by area
      if (_selectedArea != 'all' && provider['location']?['area'] != _selectedArea) return false;
      
      // Filter by rating
      final rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
      if (rating < _minRating) return false;
      
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
          final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
          return ratingB.compareTo(ratingA); // Descending
        case 'price':
          final priceA = _getAveragePrice(a);
          final priceB = _getAveragePrice(b);
          return priceA.compareTo(priceB); // Ascending
        case 'distance':
          if (widget.customerLocation != null) {
            final distanceA = a['distance_km'] as double? ?? double.infinity;
            final distanceB = b['distance_km'] as double? ?? double.infinity;
            return distanceA.compareTo(distanceB); // Ascending (closest first)
          }
          // Fallback to rating if no customer location
          final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
          final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
          return ratingB.compareTo(ratingA);
        case 'name':
        default:
          final nameA = a['provider_name'] ?? '';
          final nameB = b['provider_name'] ?? '';
          return nameA.compareTo(nameB);
      }
    });

    return filtered;
  }

  String _getPriceRange(Map<String, dynamic> provider) {
    final services = provider['services'] as List?;
    if (services == null || services.isEmpty) return 'N/A';
    
    final prices = services
        .map((s) => _parsePrice(s['price']))
        .where((price) => price != null)
        .cast<double>()
        .toList();
    
    if (prices.isEmpty) return 'N/A';
    
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    
    if (min == max) {
      return 'KSh ${min.toInt()}';
    } else {
      return 'KSh ${min.toInt()}-${max.toInt()}';
    }
  }

  double? _parsePrice(String? priceStr) {
    if (priceStr == null) return null;
    
    // Extract numbers from price string like "KSh 3,500 - 8,000"
    final numbers = RegExp(r'[\d,]+').allMatches(priceStr)
        .map((match) => match.group(0)?.replaceAll(',', '') ?? '')
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s))
        .where((n) => n != null)
        .cast<double>()
        .toList();
    
    return numbers.isNotEmpty ? numbers.first : null;
  }

  double _getAveragePrice(Map<String, dynamic> provider) {
    final services = provider['services'] as List?;
    if (services == null || services.isEmpty) return 0.0;
    
    final prices = services
        .map((s) => _parsePrice(s['price']))
        .where((price) => price != null)
        .cast<double>()
        .toList();
    
    if (prices.isEmpty) return 0.0;
    
    return prices.reduce((a, b) => a + b) / prices.length;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _sortBy = 'rating';
      _filterBy = 'all';
      _minRating = 0.0;
      _selectedArea = 'all';
    });
    _searchController.clear();
  }

  Future<void> _showManualProviderDialog() async {
    final TextEditingController nameController = TextEditingController();
    bool isLoading = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the name of the provider'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Provider Name',
                  hintText: 'e.g., ABC Auto Shop',
                  border: OutlineInputBorder(),
                ),
                enabled: !isLoading,
                autofocus: true,
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a provider name')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final newProvider = await ProviderService.quickCreateProvider(name);
                        if (newProvider != null) {
                          // Ensure consistent field names and mark as manual entry
                          final providerData = {
                            'id': newProvider['id'],
                            'provider_id': newProvider['id'],
                            'name': newProvider['name'],
                            'provider_name': newProvider['name'],
                            'is_manual': true,
                            'is_registered': false,
                          };
                          Navigator.pop(context, providerData);
                        } else {
                          setDialogState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to create provider')),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      widget.onSelect(result);
      Navigator.pop(context); // Close the provider selector
    }
  }
}
