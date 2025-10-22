import 'dart:math';
import '../data/coordinate_research.dart';

/// Coordinate Validation Service
/// Validates and scores GPS coordinates for accuracy and reliability
class CoordinateValidator {
  
  /// Validate if coordinates are within Nairobi bounds
  static bool isWithinNairobiBounds(double lat, double lng) {
    // Nairobi County bounds (approximate)
    const double minLat = -1.5;
    const double maxLat = -1.0;
    const double minLng = 36.6;
    const double maxLng = 37.0;
    
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
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
