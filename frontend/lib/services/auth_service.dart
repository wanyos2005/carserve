import 'package:driveon_car_platform/services/api_service.dart';
import 'package:driveon_car_platform/services/storage_service.dart';

/// Refactored AuthService with DRY principles applied
class AuthService {
  // Send OTP
  static Future<bool> sendCode(String email) async {
    final result = await ApiService.post("/users/send-code", {"email": email});
    
    if (result != null) {
      await StorageService.setEmail(email);
      return true;
    }
    return false;
  }

  // Verify OTP
  static Future<bool> verifyCode(String code) async {
    final email = await StorageService.getEmail();
    
    if (email == null) {
      return false;
    }

    final result = await ApiService.post("/users/verify-code", {
      'email': email, 
      'code': code
    });

    if (result != null) {
      final token = result['access_token'];
      await StorageService.setToken(token);

      // Fetch user profile
      final user = await ApiService.get("/users/me");
      if (user != null) {
        await StorageService.setUser(user);
        return true;
      }
    }
    return false;
  }

  // Get current user from storage
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await StorageService.getUser();
  }

  // Get logged-in user info from API
  static Future<Map<String, dynamic>?> getMe() async {
    return await ApiService.get("/users/me");
  }

  // Check if user has valid authentication
  static Future<bool> isAuthenticated() async {
    final token = await StorageService.getToken();
    if (token == null) return false;
    
    try {
      final userData = await getMe();
      return userData != null;
    } catch (e) {
      print('DEBUG AuthService: Authentication check failed: $e');
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    await StorageService.clearAllAuth();
  }

  // Admin Management Functions
  static Future<bool> createAdminUser(String email, {String? name}) async {
    final query = "email=$email${name != null ? '&name=$name' : ''}";
    final result = await ApiService.post("/users/admin/create?$query", {});
    return result != null;
  }

  static Future<bool> removeAdminUser(String email) async {
    return await ApiService.delete("/users/admin/remove?email=$email");
  }

  static Future<List<dynamic>> getAdminUsers() async {
    final result = await ApiService.get("/users/admin/list");
    return result?['admins'] ?? [];
  }

  // User Management Functions
  static Future<List<dynamic>> getAllUsers() async {
    final result = await ApiService.get("/users/all");
    return result is List ? result : [];
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final result = await ApiService.get("/users/search", query: {"q": query});
    return result is List ? result : [];
  }

  static Future<List<dynamic>> lookupUsersByIds(List<int> userIds) async {
    final result = await ApiService.post("/users/lookup", userIds);
    return result is List ? result : [];
  }

  static Future<Map<String, dynamic>?> testLookupUser(int userId) async {
    return await ApiService.get("/users/test-lookup/$userId");
  }

  // Link user to provider
  static Future<bool> linkUserToProvider(int userId, String providerId) async {
    final result = await ApiService.post("/users/link-user-provider", {
      "user_id": userId, 
      "provider_id": providerId
    });
    return result != null;
  }

  // Unlink user from provider
  static Future<bool> unlinkUserFromProvider(int userId, String providerId) async {
    try {
      final result = await ApiService.delete(
        "/users/unlink-user-provider",
        query: {
          "user_id": userId,
          "provider_id": providerId
        }
      );
      return result != null;
    } catch (e) {
      print("Error unlinking user from provider: $e");
      return false;
    }
  }

  // Create guest user
  static Future<Map<String, dynamic>?> createGuestUser({
    String? email, 
    String? phone, 
    String? name, 
    String? providerId,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body["email"] = email;
    if (phone != null) body["phone"] = phone;
    if (name != null) body["name"] = name;
    if (providerId != null) body["provider_id"] = providerId;
    
    return await ApiService.post("/users/guest", body);
  }

  // Get links for a specific provider
  static Future<Map<String, dynamic>?> getProviderLinks(
    String providerId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return await ApiService.get(
      "/users/provider-links/$providerId",
      query: {
        "page": page.toString(),
        "page_size": pageSize.toString(),
      },
    );
  }

  // Get all links with pagination
  static Future<Map<String, dynamic>?> getAllLinks({
    int page = 1,
    int pageSize = 20,
    String? providerId,
    int? userId,
  }) async {
    final query = <String, String>{
      "page": page.toString(),
      "page_size": pageSize.toString(),
    };
    if (providerId != null) query["provider_id"] = providerId;
    if (userId != null) query["user_id"] = userId.toString();
    
    return await ApiService.get("/users/all-links", query: query);
  }
}
