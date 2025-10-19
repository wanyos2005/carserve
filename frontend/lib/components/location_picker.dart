import 'package:flutter/material.dart';
import 'package:car_platform/services/location_service.dart';

class LocationPicker extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;
  final String label;
  final String hint;
  final Function(Map<String, dynamic> location)? onLocationSelected;
  final bool required;
  final bool showCurrentLocationButton;

  const LocationPicker({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    this.label = "Location",
    this.hint = "Tap to select location",
    this.onLocationSelected,
    this.required = false,
    this.showCurrentLocationButton = true,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  String? _selectedAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress;
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final location = await LocationService.getCurrentLocation(context: context);
      if (location != null) {
        setState(() {
          _selectedLatitude = location.latitude;
          _selectedLongitude = location.longitude;
          _selectedAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
        
        // Call callback with location data (legacy compatible)
        final locationData = LocationService.createLegacyCompatibleLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          customAddress: _selectedAddress,
        );
        
        // Add additional metadata
        locationData['accuracy'] = location.accuracy;
        locationData['timestamp'] = location.timestamp.toIso8601String();
        
        widget.onLocationSelected?.call(locationData);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showLocationPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LocationPickerModal(
        initialAddress: _selectedAddress,
        initialLatitude: _selectedLatitude,
        initialLongitude: _selectedLongitude,
        onLocationSelected: (location) {
          setState(() {
            _selectedLatitude = location['latitude'];
            _selectedLongitude = location['longitude'];
            _selectedAddress = location['address'];
          });
          widget.onLocationSelected?.call(location);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Location display card
        Card(
          child: InkWell(
            onTap: _showLocationPicker,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: _selectedAddress != null ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedAddress ?? widget.hint,
                          style: TextStyle(
                            color: _selectedAddress != null ? Colors.black87 : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  
                  if (_selectedLatitude != null && _selectedLongitude != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📍 ${LocationService.getReadableLocationName(_selectedLatitude!, _selectedLongitude!)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${_selectedLatitude!.toStringAsFixed(6)}, Lng: ${_selectedLongitude!.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[600],
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
        ),
        
        // Current location button
        if (widget.showCurrentLocationButton) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 16),
              label: Text(_isLoading ? 'Getting Location...' : 'Use Current Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class LocationPickerModal extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(Map<String, dynamic> location) onLocationSelected;

  const LocationPickerModal({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  final TextEditingController _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? '';
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final location = await LocationService.getCurrentLocation(context: context);
      if (location != null) {
        setState(() {
          _latitude = location.latitude;
          _longitude = location.longitude;
          _addressController.text = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmLocation() {
    if (_latitude != null && _longitude != null) {
      // Create legacy compatible location data
      final locationData = LocationService.createLegacyCompatibleLocation(
        latitude: _latitude!,
        longitude: _longitude!,
        customAddress: _addressController.text.trim(),
      );
      
      // Add timestamp
      locationData['timestamp'] = DateTime.now().toIso8601String();
      
      widget.onLocationSelected(locationData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Select Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Address input
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Enter address or coordinates',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          // Current location button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_isLoading ? 'Getting Location...' : 'Use Current Location'),
            ),
          ),
          const SizedBox(height: 16),
          
          // Location coordinates display
          if (_latitude != null && _longitude != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Coordinates:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Latitude: ${_latitude!.toStringAsFixed(6)}'),
                  Text('Longitude: ${_longitude!.toStringAsFixed(6)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
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
                  onPressed: _latitude != null && _longitude != null ? _confirmLocation : null,
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
