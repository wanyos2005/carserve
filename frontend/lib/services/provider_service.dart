import 'package:driveon_car_platform/services/api_service.dart';

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
        ? "/service-providers/providers/?$queryString"
        : "/service-providers/providers/";

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

  static Future<Map<String, dynamic>?> quickCreateProvider(String name) async {
    print("🔄 QuickCreateProvider: Sending request for provider: $name");
    final res = await ApiService.post("/service-providers/quick-provider", {
      "name": name,
    });
    print("🔄 QuickCreateProvider: API response: $res");
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    print("❌ QuickCreateProvider: Response is not a Map, returning null");
    return null;
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
    print("🔄 ProviderService: Attaching ${services.length} services to provider $providerId");
    print("🔄 ProviderService: Services data: $services");
    
    final result = await ApiService.post("/service-providers/$providerId/services", services);
    print("🔄 ProviderService: API response: $result");
    
    return result;
  }

  // 🔹 Ratings
  static Future<Map<String, dynamic>?> rateProvider({
    required String providerId,
    required int rating,
    String? comment,
    required int userId,
    String? bookingId,
    String? logId,
  }) async {
    final body = {
      "rating": rating,
      if (comment != null && comment.isNotEmpty) "comment": comment,
      "user_id": userId,
      if (bookingId != null) "booking_id": bookingId,
      if (logId != null) "log_id": logId,
    };
    final res = await ApiService.post("/service-providers/$providerId/ratings", body);
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
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
