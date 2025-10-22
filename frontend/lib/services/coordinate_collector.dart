import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Coordinate Collection System
/// Allows users to collect and submit real GPS coordinates for areas
class CoordinateCollector {
  static const String _collectedCoordinatesKey = 'collected_coordinates';

  /// Collect current location and allow user to name it
  static Future<Map<String, dynamic>?> collectCurrentLocation({
    required BuildContext context,
    String? suggestedAreaName,
  }) async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Show dialog to confirm area name
      final areaName = await _showAreaNameDialog(
        context,
        position.latitude,
        position.longitude,
        suggestedAreaName,
      );

      if (areaName != null && areaName.isNotEmpty) {
        final coordinateData = {
          'area_name': areaName,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
          'collected_by': 'user', // or 'admin', 'system'
          'verified': false,
          'source': 'user_collection',
        };

        // Save to local storage
        await _saveCollectedCoordinate(coordinateData);

        return coordinateData;
      }

      return null;
    } catch (e) {
      debugPrint('Error collecting coordinates: $e');
      return null;
    }
  }

  /// Show dialog for user to name the area
  static Future<String?> _showAreaNameDialog(
    BuildContext context,
    double lat,
    double lon,
    String? suggestedName,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: suggestedName ?? '',
    );

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name This Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Coordinates: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Area Name',
                hintText: 'e.g., Kasarani Mwiki, Westlands Mall',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'This will help improve location accuracy for other users',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Save collected coordinate to local storage
  static Future<void> _saveCollectedCoordinate(Map<String, dynamic> coordinate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString(_collectedCoordinatesKey);
      
      List<Map<String, dynamic>> coordinates = [];
      if (existingData != null) {
        final List<dynamic> decoded = json.decode(existingData);
        coordinates = decoded.cast<Map<String, dynamic>>();
      }
      
      coordinates.add(coordinate);
      
      await prefs.setString(_collectedCoordinatesKey, json.encode(coordinates));
      debugPrint('Saved coordinate: ${coordinate['area_name']}');
    } catch (e) {
      debugPrint('Error saving coordinate: $e');
    }
  }

  /// Get all collected coordinates
  static Future<List<Map<String, dynamic>>> getCollectedCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_collectedCoordinatesKey);
      
      if (data != null) {
        final List<dynamic> decoded = json.decode(data);
        return decoded.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting collected coordinates: $e');
      return [];
    }
  }

  /// Submit coordinates to server (when implemented)
  static Future<bool> submitCoordinatesToServer() async {
    try {
      final coordinates = await getCollectedCoordinates();
      
      if (coordinates.isEmpty) {
        return false;
      }

      // TODO: Implement server submission
      // This would send coordinates to your backend for verification
      // and potential inclusion in the main areas mapping
      
      debugPrint('Would submit ${coordinates.length} coordinates to server');
      return true;
    } catch (e) {
      debugPrint('Error submitting coordinates: $e');
      return false;
    }
  }

  /// Clear collected coordinates
  static Future<void> clearCollectedCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_collectedCoordinatesKey);
      debugPrint('Cleared collected coordinates');
    } catch (e) {
      debugPrint('Error clearing coordinates: $e');
    }
  }

  /// Get coordinates for a specific area
  static Future<List<Map<String, dynamic>>> getCoordinatesForArea(String areaName) async {
    final allCoordinates = await getCollectedCoordinates();
    return allCoordinates.where((coord) => 
      coord['area_name'].toString().toLowerCase().contains(areaName.toLowerCase())
    ).toList();
  }

  /// Export coordinates as JSON
  static Future<String> exportCoordinatesAsJson() async {
    final coordinates = await getCollectedCoordinates();
    return json.encode(coordinates);
  }

  /// Import coordinates from JSON
  static Future<bool> importCoordinatesFromJson(String jsonData) async {
    try {
      final List<dynamic> decoded = json.decode(jsonData);
      final coordinates = decoded.cast<Map<String, dynamic>>();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_collectedCoordinatesKey, json.encode(coordinates));
      
      debugPrint('Imported ${coordinates.length} coordinates');
      return true;
    } catch (e) {
      debugPrint('Error importing coordinates: $e');
      return false;
    }
  }
}

/// Widget for collecting coordinates in the app
class CoordinateCollectionWidget extends StatefulWidget {
  final String? suggestedAreaName;
  final Function(Map<String, dynamic>)? onCoordinateCollected;

  const CoordinateCollectionWidget({
    super.key,
    this.suggestedAreaName,
    this.onCoordinateCollected,
  });

  @override
  State<CoordinateCollectionWidget> createState() => _CoordinateCollectionWidgetState();
}

class _CoordinateCollectionWidgetState extends State<CoordinateCollectionWidget> {
  bool _isCollecting = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Improve Location Accuracy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve location detection by collecting real coordinates for this area.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCollecting ? null : _collectCoordinate,
                icon: _isCollecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_location),
                label: Text(_isCollecting ? 'Collecting...' : 'Collect This Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _collectCoordinate() async {
    setState(() => _isCollecting = true);

    try {
      final coordinate = await CoordinateCollector.collectCurrentLocation(
        context: context,
        suggestedAreaName: widget.suggestedAreaName,
      );

      if (coordinate != null) {
        widget.onCoordinateCollected?.call(coordinate);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location "${coordinate['area_name']}" collected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCollecting = false);
      }
    }
  }
}
