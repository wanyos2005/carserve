import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
  
  /// Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
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
      
      // Check permissions
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          if (showErrorDialog && context != null) {
            _showPermissionDeniedDialog(context);
          }
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (showErrorDialog && context != null) {
          _showPermissionPermanentlyDeniedDialog(context);
        }
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
  
  /// Get address from coordinates (reverse geocoding)
  static Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      // Note: This would require a geocoding service like Google Maps API
      // For now, return coordinates as string
      return '$lat, $lon';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  /// Get readable location name from coordinates (Nairobi areas mapping)
  static String getReadableLocationName(double lat, double lon) {
    // Nairobi areas mapping (from seed data)
    final nairobiAreas = [
      {"name": "Westlands", "lat": -1.2657, "lng": 36.8065, "tolerance": 0.05},
      {"name": "Karen", "lat": -1.3197, "lng": 36.6788, "tolerance": 0.05},
      {"name": "Runda", "lat": -1.2000, "lng": 36.8000, "tolerance": 0.05},
      {"name": "Kilimani", "lat": -1.3000, "lng": 36.7833, "tolerance": 0.05},
      {"name": "Lavington", "lat": -1.2833, "lng": 36.7667, "tolerance": 0.05},
      {"name": "Eastleigh", "lat": -1.2667, "lng": 36.8500, "tolerance": 0.05},
      {"name": "South B", "lat": -1.3167, "lng": 36.8333, "tolerance": 0.05},
      {"name": "Industrial Area", "lat": -1.3000, "lng": 36.8167, "tolerance": 0.05},
      {"name": "CBD", "lat": -1.2921, "lng": 36.8219, "tolerance": 0.05},
      {"name": "Kasarani", "lat": -1.2167, "lng": 36.9000, "tolerance": 0.05},
      {"name": "Thika Road", "lat": -1.2000, "lng": 36.8500, "tolerance": 0.05},
      {"name": "Mombasa Road", "lat": -1.3167, "lng": 36.8833, "tolerance": 0.05},
    ];

    // Find the closest area
    for (final area in nairobiAreas) {
      final areaLat = area["lat"] as double;
      final areaLng = area["lng"] as double;
      final tolerance = area["tolerance"] as double;
      
      if ((lat - areaLat).abs() <= tolerance && (lon - areaLng).abs() <= tolerance) {
        return area["name"] as String;
      }
    }
    
    // If no specific area found, return generic Nairobi
    return "Nairobi";
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
  
  /// Show permission denied dialog
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to find nearby service providers and calculate distances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Show permission permanently denied dialog
  static void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission has been permanently denied. Please enable it in app settings to use location features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
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
}
