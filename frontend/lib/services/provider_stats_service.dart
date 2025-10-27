import 'package:driveon_car_platform/services/api_service.dart';

class ProviderStatsService {
  static Future<Map<String, dynamic>?> getProviderStats(String providerId) async {
    try {
      final response = await ApiService.get('/service-providers/$providerId/stats');
      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      print('Error fetching provider stats: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getGlobalStats() async {
    try {
      final response = await ApiService.get('/service-providers/stats');
      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      print('Error fetching global stats: $e');
    }
    return null;
  }
}
