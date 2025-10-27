import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../data/nairobi_areas.dart';
import '../data/coordinate_research.dart';
import 'unified_permission_service.dart';

class LocationService {
  static const double _defaultAccuracy = 10.0; // meters
  
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Check location permission status
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }
  
  /// Request location permission (delegates to UnifiedPermissionService)
  static Future<bool> requestLocationPermission({BuildContext? context}) async {
    return await UnifiedPermissionService.requestLocationPermission(context: context);
  }
  
  /// Get current location with permission handling
  static Future<Position?> getCurrentLocation({
    double accuracy = _defaultAccuracy,
    bool showErrorDialog = true,
    BuildContext? context,
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showErrorDialog && context != null) {
          _showLocationServiceDialog(context);
        }
        return null;
      }
      
      // Check permissions using unified service
      bool hasPermission = await requestLocationPermission(context: context);
      if (!hasPermission) {
        return null;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (showErrorDialog && context != null) {
        _showLocationErrorDialog(context, e.toString());
      }
      return null;
    }
  }
  
  /// Get location with specific accuracy
  static Future<Position?> getLocationWithAccuracy(LocationAccuracy accuracy) async {
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: accuracy);
    } catch (e) {
      debugPrint('Error getting location with accuracy: $e');
      return null;
    }
  }
  
  /// Calculate distance between two points in kilometers
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }
  
  /// Get address from coordinates (reverse geocoding) - Enhanced hybrid approach
  static Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      // First try: Static mapping (fast, reliable, offline)
      final staticResult = _getStaticLocationName(lat, lon);
      if (staticResult != "Nairobi") {
        return staticResult;
      }
      
      // Second try: Cached geocoding results
      final cachedResult = _getCachedLocationName(lat, lon);
      if (cachedResult != null) {
        return cachedResult;
      }
      
      // Third try: OpenStreetMap API (when available)
      final apiResult = await _getOpenStreetMapAddress(lat, lon);
      if (apiResult != null) {
        // Cache the result for future use
        _cacheLocationName(lat, lon, apiResult);
        return apiResult;
      }
      
      // Fallback: Return coordinates
      return '$lat, $lon';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  /// Get address from OpenStreetMap Nominatim API (free, no credit card required)
  static Future<String?> _getOpenStreetMapAddress(double lat, double lon) async {
    try {
      // Using OpenStreetMap Nominatim (free, no credit card required)
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1'),
        headers: {'User-Agent': 'CarPlatform/1.0'}, // Required by Nominatim
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] as String?;
        
        if (address != null && address.isNotEmpty) {
          // Extract just the area name for better UX
          return _extractAreaName(address);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting address from OSM: $e');
      return null;
    }
  }

  /// Extract area name from full address
  static String _extractAreaName(String fullAddress) {
    // For Kenya addresses, try to extract the most relevant area
    final parts = fullAddress.split(',');
    
    // Look for common Kenyan area indicators
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('Nairobi') || 
          trimmed.contains('Mombasa') || 
          trimmed.contains('Kisumu') ||
          trimmed.contains('Nakuru') ||
          trimmed.contains('CBD') ||
          trimmed.contains('Road') ||
          trimmed.contains('Area')) {
        return trimmed;
      }
    }
    
    // Return first meaningful part
    return parts.isNotEmpty ? parts.first.trim() : fullAddress;
  }

  /// Cache location name for future use
  static void _cacheLocationName(double lat, double lon, String locationName) {
    // Simple in-memory cache for now
    // TODO: Implement persistent caching with SharedPreferences
    final key = "location_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}";
    _locationCache[key] = locationName;
  }

  // Simple in-memory cache
  static final Map<String, String> _locationCache = {};

  /// Get readable location name from coordinates (Enhanced hybrid approach)
  static String getReadableLocationName(double lat, double lon) {
    // First try: Static mapping (fast, reliable, offline)
    final staticResult = _getStaticLocationName(lat, lon);
    if (staticResult != "Nairobi") {
      return staticResult;
    }
    
    // Second try: Cached geocoding results
    final cachedResult = _getCachedLocationName(lat, lon);
    if (cachedResult != null) {
      return cachedResult;
    }
    
    // Fallback: Generic location
    return "Nairobi";
  }

  /// Static mapping for known Nairobi areas (fast, offline, reliable)
  /// Now uses comprehensive mapping with sub-areas
  static String _getStaticLocationName(double lat, double lon) {
    // Use the comprehensive Nairobi areas mapping
    final areaName = NairobiAreas.getAreaByCoordinates(lat, lon);
    return areaName ?? "Nairobi";
  }

  /// Get cached geocoding result (if available)
  static String? _getCachedLocationName(double lat, double lon) {
    final key = "location_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}";
    return _locationCache[key];
  }

  /// Create location data compatible with legacy format
  static Map<String, dynamic> createLegacyCompatibleLocation({
    required double latitude,
    required double longitude,
    String? customAddress,
  }) {
    final readableName = getReadableLocationName(latitude, longitude);
    final address = customAddress ?? '$latitude, $longitude';
    
    return {
      // Legacy format (for backward compatibility)
      'name': readableName,
      'lat': latitude,
      'lng': longitude,
      
      // Enhanced format (for new features)
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'area': readableName,
      'readable_name': readableName,
    };
  }
  
  /// Show location service disabled dialog
  static void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled. Please enable them in your device settings to use location-based features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  
  /// Show location error dialog
  static void _showLocationErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: Text('Failed to get location: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Get location for provider onboarding
  static Future<Map<String, dynamic>?> getLocationForProviderOnboarding(BuildContext context) async {
    final position = await getCurrentLocation(context: context);
    if (position == null) return null;
    
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': position.timestamp.toIso8601String(),
      'address': await getAddressFromCoordinates(position.latitude, position.longitude),
    };
  }
  
  /// Get location for booking
  static Future<Map<String, dynamic>?> getLocationForBooking(BuildContext context) async {
    final position = await getCurrentLocation(context: context);
    if (position == null) return null;
    
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': position.timestamp.toIso8601String(),
      'address': await getAddressFromCoordinates(position.latitude, position.longitude),
    };
  }
  
  /// Calculate distance between customer and provider
  static double? calculateProviderDistance(
    Map<String, dynamic> customerLocation,
    Map<String, dynamic> providerLocation,
  ) {
    try {
      final customerLat = customerLocation['latitude'] as double?;
      final customerLon = customerLocation['longitude'] as double?;
      final providerLat = providerLocation['latitude'] as double?;
      final providerLon = providerLocation['longitude'] as double?;
      
      if (customerLat == null || customerLon == null || 
          providerLat == null || providerLon == null) {
        return null;
      }
      
      return calculateDistance(customerLat, customerLon, providerLat, providerLon);
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return null;
    }
  }
  
  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  // ============================================================================
  // COORDINATE COLLECTION FUNCTIONALITY
  // ============================================================================
  
  static const String _collectedCoordinatesKey = 'collected_coordinates';

  /// Collect current location and allow user to name it
  static Future<Map<String, dynamic>?> collectCurrentLocation({
    required BuildContext context,
    String? suggestedAreaName,
  }) async {
    try {
      // Check location permission first
      bool hasPermission = await UnifiedPermissionService.requestLocationPermission(context: context);
      if (!hasPermission) {
        return null;
      }
      
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

  // ============================================================================
  // COORDINATE VALIDATION FUNCTIONALITY
  // ============================================================================

  /// Validate if coordinates are within Nairobi bounds
  static bool isWithinNairobiBounds(double lat, double lng) {
    // Nairobi County bounds (approximate)
    const double minLat = -1.5;
    const double maxLat = -1.0;
    const double minLng = 36.6;
    const double maxLng = 37.0;
    
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Validate coordinate accuracy based on multiple factors
  static CoordinateValidationResult validateCoordinate({
    required double lat,
    required double lng,
    String? areaName,
    String? source,
    double? accuracy,
  }) {
    final result = CoordinateValidationResult();
    
    // Check if within Nairobi bounds
    result.isWithinBounds = isWithinNairobiBounds(lat, lng);
    if (result.isWithinBounds) result.score += 20;
    
    // Check accuracy (if provided)
    if (accuracy != null) {
      if (accuracy <= 10) {
        result.score += 30; // High accuracy
        result.accuracyLevel = 'High';
      } else if (accuracy <= 50) {
        result.score += 20; // Medium accuracy
        result.accuracyLevel = 'Medium';
      } else if (accuracy <= 100) {
        result.score += 10; // Low accuracy
        result.accuracyLevel = 'Low';
      } else {
        result.accuracyLevel = 'Very Low';
      }
    }
    
    // Check source reliability
    if (source != null) {
      switch (source.toLowerCase()) {
        case 'google maps':
          result.score += 25;
          result.sourceReliability = 'High';
          break;
        case 'openstreetmap':
          result.score += 20;
          result.sourceReliability = 'Medium';
          break;
        case 'user_collection':
          result.score += 15;
          result.sourceReliability = 'Medium';
          break;
        case 'estimated':
          result.score += 5;
          result.sourceReliability = 'Low';
          break;
        default:
          result.score += 10;
          result.sourceReliability = 'Unknown';
      }
    }
    
    // Check against known areas
    if (areaName != null) {
      final knownCoordinates = CoordinateResearch.getAllResearchedCoordinates();
      final knownArea = knownCoordinates[areaName];
      
      if (knownArea != null) {
        final distance = calculateDistance(
          lat, lng,
          knownArea['lat'] as double,
          knownArea['lng'] as double,
        );
        
        if (distance <= 1.0) {
          result.score += 25; // Very close to known area
          result.distanceToKnown = distance;
        } else if (distance <= 5.0) {
          result.score += 15; // Close to known area
          result.distanceToKnown = distance;
        } else if (distance <= 10.0) {
          result.score += 5; // Somewhat close
          result.distanceToKnown = distance;
        } else {
          result.distanceToKnown = distance;
        }
      }
    }
    
    // Determine overall quality
    if (result.score >= 80) {
      result.quality = 'Excellent';
    } else if (result.score >= 60) {
      result.quality = 'Good';
    } else if (result.score >= 40) {
      result.quality = 'Fair';
    } else if (result.score >= 20) {
      result.quality = 'Poor';
    } else {
      result.quality = 'Very Poor';
    }
    
    return result;
  }

  /// Find closest known area to given coordinates
  static String? findClosestKnownArea(double lat, double lng) {
    final knownCoordinates = CoordinateResearch.getAllResearchedCoordinates();
    double minDistance = double.infinity;
    String? closestArea;
    
    for (final entry in knownCoordinates.entries) {
      final distance = calculateDistance(
        lat, lng,
        entry.value['lat'] as double,
        entry.value['lng'] as double,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestArea = entry.key;
      }
    }
    
    return minDistance <= 10.0 ? closestArea : null; // Within 10km
  }

  /// Suggest improvements for coordinate accuracy
  static List<String> suggestImprovements(CoordinateValidationResult result) {
    final suggestions = <String>[];
    
    if (!result.isWithinBounds) {
      suggestions.add('Coordinates are outside Nairobi bounds');
    }
    
    if (result.accuracyLevel == 'Low' || result.accuracyLevel == 'Very Low') {
      suggestions.add('Improve GPS accuracy by using high-accuracy mode');
    }
    
    if (result.sourceReliability == 'Low' || result.sourceReliability == 'Unknown') {
      suggestions.add('Verify coordinates with multiple sources');
    }
    
    if (result.distanceToKnown != null && result.distanceToKnown! > 5.0) {
      suggestions.add('Coordinates are far from known areas - verify location');
    }
    
    if (result.score < 40) {
      suggestions.add('Consider collecting new coordinates for this location');
    }
    
    return suggestions;
  }
}

/// Result of coordinate validation
class CoordinateValidationResult {
  bool isWithinBounds = false;
  int score = 0;
  String quality = 'Unknown';
  String accuracyLevel = 'Unknown';
  String sourceReliability = 'Unknown';
  double? distanceToKnown;
  
  @override
  String toString() {
    return 'CoordinateValidationResult('
        'isWithinBounds: $isWithinBounds, '
        'score: $score, '
        'quality: $quality, '
        'accuracyLevel: $accuracyLevel, '
        'sourceReliability: $sourceReliability, '
        'distanceToKnown: $distanceToKnown'
        ')';
  }
}
