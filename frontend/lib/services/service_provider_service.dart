// lib/services/service_provider_service.dart
import 'api_service.dart';

class ServiceProviderService {
  // 🔹 Provider Categories
  static Future<List<dynamic>> getProviderCategories() async {
    final res = await ApiService.get("/service-providers/categories/provider-categories");
    return res is List ? res : [];
  }

  static Future<dynamic> createProviderCategory(Map<String, dynamic> data) async {
    return await ApiService.post("/service-providers/categories/provider-categories", data);
  }

  // 🔹 Service Categories
  static Future<List<dynamic>> getServiceCategories() async {
    final res = await ApiService.get("/service-providers/categories/service-categories");
    return res is List ? res : [];
  }

  static Future<dynamic> createServiceCategory(Map<String, dynamic> data) async {
    return await ApiService.post("/service-providers/categories/service-categories", data);
  }

  // 🔹 Providers
  static Future<List<dynamic>> getProviders({int? categoryId}) async {
    final query = categoryId != null ? "?category_id=$categoryId" : "";
    final res = await ApiService.get("/service-providers$query");
    return res is List ? res : [];
  }

  static Future<Map<String, dynamic>?> getProviderDetails(String providerId) async {
    final res = await ApiService.get("/service-providers/$providerId");
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  static Future<dynamic> createProvider(Map<String, dynamic> data) async {
    return await ApiService.post("/service-providers/", data);
  }

  static Future<dynamic> updateProvider(String id, Map<String, dynamic> data) async {
    return await ApiService.put("/service-providers/$id", data);
  }

  static Future<bool> deleteProvider(String id) async {
    return await ApiService.delete("/service-providers/$id");
  }

  // 🔹 Services
  static Future<List<dynamic>> getProviderServices(String providerId) async {
    final res = await ApiService.get("/service-providers/$providerId/services");
    return res is List ? res : [];
  }

  /// ✅ Global service creation
  static Future<Map<String, dynamic>?> createGlobalService(Map<String, dynamic> data) async {
    final res = await ApiService.post("/service-providers/services", data);
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  static Future<dynamic> updateService(String serviceId, Map<String, dynamic> data) async {
    return await ApiService.put("/service-providers/services/$serviceId", data);
  }

  static Future<bool> deleteService(String serviceId) async {
    return await ApiService.delete("/service-providers/services/$serviceId");
  }

  /// ✅ Attach services by UUIDs
  static Future<dynamic> attachServicesToProvider(String providerId, List<String> serviceIds) async {
    return await ApiService.post("/service-providers/$providerId/services", serviceIds);
  }
}
