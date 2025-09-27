// lib/services/provider_service.dart
import 'package:car_platform/services/api_service.dart';

class ProviderService {
  static Future<List<dynamic>> listProviders() async {
    final res = await ApiService.get("/service-providers/");
    return res ?? [];
  }

  static Future<Map<String, dynamic>?> getProvider(String id) async {
    return await ApiService.get("/service-providers/$id");
  }
  
  static Future<Map<String, dynamic>?> getService(String id) async {
    return await ApiService.get("/service-providers/services/$id");
  }
}


