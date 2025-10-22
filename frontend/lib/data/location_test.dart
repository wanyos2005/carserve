import 'nairobi_areas.dart';
import 'coordinate_research.dart';
import '../services/coordinate_validator.dart';

/// Comprehensive test file to demonstrate all location improvements
class LocationTest {
  static void testNairobiAreas() {
    print('=== Enhanced Nairobi Areas Coverage Test ===\n');
    
    // Test coordinates for different areas
    final testCoordinates = [
      {'name': 'CBD City Hall', 'lat': -1.2931, 'lng': 36.8209},
      {'name': 'Westlands Mall', 'lat': -1.2637, 'lng': 36.8045},
      {'name': 'Karen Shopping Centre', 'lat': -1.3187, 'lng': 36.6798},
      {'name': 'Kasarani Stadium', 'lat': -1.2200, 'lng': 36.9100},
      {'name': 'Kasarani Mwiki', 'lat': -1.2100, 'lng': 36.8900},
      {'name': 'Garden City Mall', 'lat': -1.1900, 'lng': 36.8400},
      {'name': 'Two Rivers Mall', 'lat': -1.2700, 'lng': 36.8000},
      {'name': 'JKIA Airport', 'lat': -1.3200, 'lng': 36.9200},
    ];
    
    print('Testing ${testCoordinates.length} locations:\n');
    
    for (final coord in testCoordinates) {
      final areaName = NairobiAreas.getAreaByCoordinates(
        coord['lat'] as double, 
        coord['lng'] as double
      );
      
      // Validate coordinates
      final validation = CoordinateValidator.validateCoordinate(
        lat: coord['lat'] as double,
        lng: coord['lng'] as double,
        areaName: coord['name'] as String,
        source: 'Google Maps',
        accuracy: 10.0,
      );
      
      print('📍 ${coord['name']}');
      print('   Coordinates: ${coord['lat']}, ${coord['lng']}');
      print('   Detected Area: ${areaName ?? "Not found"}');
      print('   Validation: ${validation.quality} (Score: ${validation.score})');
      print('   Accuracy: ${validation.accuracyLevel}');
      print('   Source: ${validation.sourceReliability}');
      print('');
    }
    
    // Show statistics
    print('=== Coverage Statistics ===');
    print('Total areas mapped: ${NairobiAreas.totalAreas}');
    print('');
    
    // Show areas by type
    final commercialAreas = NairobiAreas.getAreasByType('commercial');
    final residentialAreas = NairobiAreas.getAreasByType('residential');
    final industrialAreas = NairobiAreas.getAreasByType('industrial');
    
    print('Commercial areas: ${commercialAreas.length}');
    print('Residential areas: ${residentialAreas.length}');
    print('Industrial areas: ${industrialAreas.length}');
    print('');
    
    // Show verified areas
    final verifiedAreas = NairobiAreas.areas.where((area) => area['verified'] == true).toList();
    print('Verified areas: ${verifiedAreas.length}');
    for (final area in verifiedAreas) {
      print('  ✅ ${area['name']} (${area['source']})');
    }
    print('');
  }

  static void testCoordinateResearch() {
    print('=== Coordinate Research Test ===\n');
    
    final researchedCoordinates = CoordinateResearch.getAllResearchedCoordinates();
    print('Researched coordinates: ${researchedCoordinates.length}');
    
    // Test Kasarani areas
    final kasaraniAreas = CoordinateResearch.getCoordinatesByType('kasarani');
    print('\nKasarani sub-areas: ${kasaraniAreas.length}');
    for (final entry in kasaraniAreas.entries) {
      final accuracy = CoordinateResearch.getCoordinateAccuracyScore(entry.value);
      print('  📍 ${entry.key}');
      print('     Coordinates: ${entry.value['lat']}, ${entry.value['lng']}');
      print('     Source: ${entry.value['source']}');
      print('     Accuracy Score: $accuracy/100');
      print('     Notes: ${entry.value['notes']}');
      print('');
    }
  }

  static void testCoordinateValidation() {
    print('=== Coordinate Validation Test ===\n');
    
    // Test various coordinate scenarios
    final testCases = [
      {
        'name': 'Valid CBD coordinates',
        'lat': -1.2921,
        'lng': 36.8219,
        'areaName': 'CBD',
        'source': 'Google Maps',
        'accuracy': 5.0,
      },
      {
        'name': 'Invalid coordinates (outside Nairobi)',
        'lat': -2.0,
        'lng': 35.0,
        'areaName': 'Unknown',
        'source': 'Estimated',
        'accuracy': 100.0,
      },
      {
        'name': 'Low accuracy coordinates',
        'lat': -1.3000,
        'lng': 36.8000,
        'areaName': 'Industrial Area',
        'source': 'User Collection',
        'accuracy': 50.0,
      },
    ];
    
    for (final testCase in testCases) {
      final validation = CoordinateValidator.validateCoordinate(
        lat: testCase['lat'] as double,
        lng: testCase['lng'] as double,
        areaName: testCase['areaName'] as String?,
        source: testCase['source'] as String?,
        accuracy: testCase['accuracy'] as double?,
      );
      
      print('🧪 ${testCase['name']}');
      print('   Coordinates: ${testCase['lat']}, ${testCase['lng']}');
      print('   Quality: ${validation.quality}');
      print('   Score: ${validation.score}/100');
      print('   Within bounds: ${validation.isWithinBounds}');
      print('   Accuracy level: ${validation.accuracyLevel}');
      print('   Source reliability: ${validation.sourceReliability}');
      
      final suggestions = CoordinateValidator.suggestImprovements(validation);
      if (suggestions.isNotEmpty) {
        print('   Suggestions:');
        for (final suggestion in suggestions) {
          print('     - $suggestion');
        }
      }
      print('');
    }
  }

  static void testClosestAreaDetection() {
    print('=== Closest Area Detection Test ===\n');
    
    final testCoordinates = [
      {'lat': -1.2100, 'lng': 36.8900, 'expected': 'Kasarani Mwiki'},
      {'lat': -1.2637, 'lng': 36.8045, 'expected': 'Westlands Mall'},
      {'lat': -1.3200, 'lng': 36.9200, 'expected': 'JKIA'},
    ];
    
    for (final coord in testCoordinates) {
      final closestArea = CoordinateValidator.findClosestKnownArea(
        coord['lat'] as double,
        coord['lng'] as double,
      );
      
      print('📍 Coordinates: ${coord['lat']}, ${coord['lng']}');
      print('   Expected: ${coord['expected']}');
      print('   Detected: ${closestArea ?? "No close area found"}');
      print('   Match: ${closestArea == coord['expected'] ? "✅" : "❌"}');
      print('');
    }
  }

  static void runAllTests() {
    print('🚀 Running All Location Tests...\n');
    
    testNairobiAreas();
    testCoordinateResearch();
    testCoordinateValidation();
    testClosestAreaDetection();
    
    print('✅ All tests completed!');
  }
}
