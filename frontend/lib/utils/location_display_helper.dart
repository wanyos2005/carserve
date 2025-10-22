class LocationDisplayHelper {
  /// Format location data for user-friendly display
  /// Hides technical details like longitude/latitude and shows only readable information
  static String formatLocationForDisplay(Map<String, dynamic>? location) {
    if (location == null) return 'Location not specified';
    
    // Priority order for display: readable_name > address > area > name
    final readableName = location['readable_name']?.toString();
    final address = location['address']?.toString();
    final area = location['area']?.toString();
    final name = location['name']?.toString();
    
    // Use the most descriptive available field
    if (readableName != null && readableName.isNotEmpty) {
      return readableName;
    } else if (address != null && address.isNotEmpty) {
      return address;
    } else if (area != null && area.isNotEmpty) {
      return area;
    } else if (name != null && name.isNotEmpty) {
      return name;
    }
    
    return 'Location not specified';
  }
  
  /// Get a short version of the location for compact display
  static String formatLocationShort(Map<String, dynamic>? location) {
    if (location == null) return 'Not specified';
    
    // For short display, prefer area or name
    final area = location['area']?.toString();
    final name = location['name']?.toString();
    
    if (area != null && area.isNotEmpty) {
      return area;
    } else if (name != null && name.isNotEmpty) {
      return name;
    }
    
    return 'Not specified';
  }
  
  /// Check if location has valid coordinates (for distance calculations)
  static bool hasValidCoordinates(Map<String, dynamic>? location) {
    if (location == null) return false;
    
    final lat = location['latitude'] ?? location['lat'];
    final lng = location['longitude'] ?? location['lng'];
    
    return lat != null && lng != null && 
           lat is num && lng is num &&
           lat >= -90 && lat <= 90 &&
           lng >= -180 && lng <= 180;
  }
  
  /// Extract coordinates for calculations (returns null if invalid)
  static Map<String, double>? getCoordinates(Map<String, dynamic>? location) {
    if (!hasValidCoordinates(location)) return null;
    
    final lat = location!['latitude'] ?? location['lat'];
    final lng = location['longitude'] ?? location['lng'];
    
    return {
      'latitude': lat.toDouble(),
      'longitude': lng.toDouble(),
    };
  }
  
  /// Format location for provider display (shows area and distance if available)
  static String formatProviderLocation(Map<String, dynamic>? location, {double? distanceKm}) {
    final baseLocation = formatLocationShort(location);
    
    if (distanceKm != null) {
      final distanceText = _formatDistance(distanceKm);
      return '$baseLocation ($distanceText)';
    }
    
    return baseLocation;
  }
  
  static String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.toStringAsFixed(0)}km';
    }
  }
}
