// lib/services/global_service_api.dart
import 'package:driveon_car_platform/services/api_service.dart';

class GlobalServiceApi {
  // 🔹 Service Categories
  static Future<List<dynamic>> getServiceCategories() async {
    final res = await ApiService.get("/service-providers/categories/service-categories");
    return res is List ? res : [];
  }

  static Future<dynamic> createServiceCategory(Map<String, dynamic> data) async {
    return await ApiService.post("/service-providers/categories/service-categories", data);
  }

  // 🔹 Global Services
  static Future<List<dynamic>> getAllGlobalServices() async {
    final res = await ApiService.get("/service-providers/services-with-categories");
    return res is List ? res : [];
  }

  static Future<List<dynamic>> getGlobalServicesByCategory(int categoryId) async {
    final res = await ApiService.get("/service-providers/services?category_id=$categoryId");
    return res is List ? res : [];
  }

  static Future<Map<String, dynamic>?> getGlobalService(String id) async {
    final res = await ApiService.get("/service-providers/services/$id");
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createGlobalService(Map<String, dynamic> data) async {
    final res = await ApiService.post("/service-providers/services", data);
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  static Future<bool> deleteGlobalService(String serviceId) async {
    return await ApiService.delete("/service-providers/services/$serviceId");
  }
}
