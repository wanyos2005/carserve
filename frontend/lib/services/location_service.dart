import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/nairobi_areas.dart';

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
