import 'package:car_platform/services/api_service.dart';

class ProviderService {
  // 🔹 Providers
  static Future<List<dynamic>> getProviders({
    int? categoryId,
    String? serviceId,
  }) async {
    // Build query string dynamically
    final queryParams = <String, String>{};
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (serviceId != null) queryParams['service_id'] = serviceId;

    final queryString = queryParams.entries
        .map((e) => "${e.key}=${Uri.encodeComponent(e.value)}")
        .join("&");

    final url = queryString.isNotEmpty
        ? "/service-providers/?$queryString"
        : "/service-providers";

    final res = await ApiService.get(url);
    return res is List ? res : [];
  }

  /// 🔹 Fetch providers by a full URL (used for multi-service filtering)
  static Future<List<dynamic>> getProvidersByUrl(String url) async {
    final res = await ApiService.get(url);
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

  static Future<bool> deleteProvider(String providerId) async {
    return await ApiService.delete("/service-providers/$providerId");
  }

  // 🔹 Provider ↔ Services
  static Future<List<dynamic>> getProviderServices(String providerId) async {
    final res = await ApiService.get("/service-providers/$providerId/services");
    return res is List ? res : [];
  }

  static Future<dynamic> attachServicesToProvider(String providerId, List<Map<String,dynamic>> services) async {
    return await ApiService.post("/service-providers/$providerId/services", services);
  }
  // 🔹 Categories
  static Future<List<dynamic>> getProviderCategories() async {
    final res = await ApiService.get("/service-providers/categories/provider-categories");
    return res is List ? res : [];
  }

  static Future<dynamic> createProviderCategory(Map<String, dynamic> data) async {
      return await ApiService.post("/service-providers/categories/provider-categories", data);
    
  }
  static Future<List<dynamic>> getServiceTemplates(String providerId) async {
    final res = await ApiService.get("/service-providers/$providerId/templates");
    return res is List ? res : [];
  }
  static Future<dynamic> createServiceTemplate(String providerId, Map<String, dynamic> data) async {
    return await ApiService.post("/service-providers/$providerId/templates", data);
  }


}
