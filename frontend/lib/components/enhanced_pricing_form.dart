import 'package:flutter/material.dart';

/// Enhanced pricing form component that supports structured pricing fields
/// according to the database schema requirements
class EnhancedPricingForm extends StatefulWidget {
  final Map<String, dynamic> currentValues;
  final Function(Map<String, dynamic>) onChanged;
  final bool required;

  const EnhancedPricingForm({
    super.key,
    required this.currentValues,
    required this.onChanged,
    this.required = true,
  });

  @override
  State<EnhancedPricingForm> createState() => _EnhancedPricingFormState();
}

class _EnhancedPricingFormState extends State<EnhancedPricingForm> {
  late String _priceType;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _unitController;
  late bool _negotiable;

  @override
  void initState() {
    super.initState();
    _priceType = widget.currentValues['price_type'] ?? 'range';
    _negotiable = widget.currentValues['negotiable'] ?? true;
    
    _minPriceController = TextEditingController(
      text: widget.currentValues['min_price']?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.currentValues['max_price']?.toString() ?? '',
    );
    _unitController = TextEditingController(
      text: widget.currentValues['unit'] ?? '',
    );

    _minPriceController.addListener(_updateValues);
    _maxPriceController.addListener(_updateValues);
    _unitController.addListener(_updateValues);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _updateValues() {
    final values = Map<String, dynamic>.from(widget.currentValues);
    values['price_type'] = _priceType;
    values['negotiable'] = _negotiable;
    values['currency'] = 'KES';
    
    if (_priceType == 'fixed' || _priceType == 'range' || _priceType == 'per_unit') {
      values['min_price'] = double.tryParse(_minPriceController.text) ?? 0.0;
      if (_priceType == 'range') {
        values['max_price'] = double.tryParse(_maxPriceController.text) ?? 0.0;
      } else {
        values['max_price'] = values['min_price'];
      }
    }
    
    if (_priceType == 'per_unit') {
      values['unit'] = _unitController.text;
    }
    
    // Generate display price for legacy compatibility
    values['price'] = _generateDisplayPrice();
    
    widget.onChanged(values);
  }

  String _generateDisplayPrice() {
    switch (_priceType) {
      case 'free':
        return 'Free';
      case 'variable':
        return 'Contact for pricing';
      case 'fixed':
        final minPrice = double.tryParse(_minPriceController.text);
        if (minPrice != null) {
          return 'KES ${minPrice.toStringAsFixed(0)}';
        }
        return 'Contact for pricing';
      case 'range':
        final minPrice = double.tryParse(_minPriceController.text);
        final maxPrice = double.tryParse(_maxPriceController.text);
        if (minPrice != null && maxPrice != null) {
          return 'KES ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)}';
        }
        return 'Contact for pricing';
      case 'per_unit':
        final minPrice = double.tryParse(_minPriceController.text);
        final unit = _unitController.text;
        if (minPrice != null && unit.isNotEmpty) {
          final unitText = unit == 'per_liter' ? '/liter' : 
                          unit == 'per_hour' ? '/hour' : '/unit';
          return 'KES ${minPrice.toStringAsFixed(0)}$unitText';
        }
        return 'Contact for pricing';
      default:
        return 'Contact for pricing';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Type Selection
        _buildPriceTypeSelector(),
        const SizedBox(height: 16),
        
        // Dynamic pricing fields based on selected type
        _buildDynamicPricingFields(),
        const SizedBox(height: 16),
        
        // Negotiable toggle
        _buildNegotiableToggle(),
        const SizedBox(height: 16),
        
        // Preview of generated price
        _buildPricePreview(),
      ],
    );
  }

  Widget _buildPriceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Type ${widget.required ? "*" : ""}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How do you want to price this service?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPriceTypeChip('fixed', 'Fixed Price', Icons.attach_money, Colors.green),
            _buildPriceTypeChip('range', 'Price Range', Icons.trending_up, Colors.blue),
            _buildPriceTypeChip('per_unit', 'Per Unit', Icons.speed, Colors.orange),
            _buildPriceTypeChip('free', 'Free Service', Icons.free_breakfast, Colors.purple),
            _buildPriceTypeChip('variable', 'Contact for Quote', Icons.phone, Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _priceType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _priceType = type;
        });
        _updateValues();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicPricingFields() {
    switch (_priceType) {
      case 'fixed':
        return _buildFixedPriceFields();
      case 'range':
        return _buildRangePriceFields();
      case 'per_unit':
        return _buildPerUnitPriceFields();
      case 'free':
        return _buildFreeServiceInfo();
      case 'variable':
        return _buildVariablePriceInfo();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFixedPriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fixed Price (KES)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _minPriceController,
          decoration: const InputDecoration(
            labelText: 'Price Amount',
            hintText: 'e.g., 5000',
            prefixText: 'KES ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money, color: Colors.green),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => _updateValues(),
        ),
        const SizedBox(height: 8),
        Text(
          'This service has a fixed price that customers will pay.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRangePriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (KES)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minPriceController,
                decoration: const InputDecoration(
                  labelText: 'Min Price',
                  hintText: 'e.g., 3000',
                  prefixText: 'KES ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateValues(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxPriceController,
                decoration: const InputDecoration(
                  labelText: 'Max Price',
                  hintText: 'e.g., 8000',
                  prefixText: 'KES ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Customers will see a price range. Final price depends on specific requirements.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPerUnitPriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per Unit Pricing (KES)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _minPriceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Unit',
                  hintText: 'e.g., 150',
                  prefixText: 'KES ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateValues(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                value: _unitController.text.isNotEmpty ? _unitController.text : null,
                items: const [
                  DropdownMenuItem(value: 'per_liter', child: Text('Per Liter')),
                  DropdownMenuItem(value: 'per_hour', child: Text('Per Hour')),
                  DropdownMenuItem(value: 'per_km', child: Text('Per KM')),
                  DropdownMenuItem(value: 'per_unit', child: Text('Per Unit')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _unitController.text = value;
                    _updateValues();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Price is calculated based on quantity (e.g., liters of fuel, hours of work).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFreeServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.free_breakfast, color: Colors.purple[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Service',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple[700],
                  ),
                ),
                Text(
                  'This service is provided free of charge to customers.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.purple[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariablePriceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Colors.grey[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact for Pricing',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Customers will need to contact you directly for pricing information.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiableToggle() {
    return Row(
      children: [
        Switch(
          value: _negotiable,
          onChanged: (value) {
            setState(() {
              _negotiable = value;
            });
            _updateValues();
          },
          activeColor: Colors.blue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price is negotiable',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Allow customers to negotiate the final price',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricePreview() {
    final displayPrice = _generateDisplayPrice();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  displayPrice,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  'This is how customers will see your pricing',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
