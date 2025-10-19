import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

//

class AuthService {
  static const String baseUrl = "http://152.70.28.112";

  // Send OTP
  // Send OTP
  static Future<bool> sendCode(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/send-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("email", email); // ✅ FIX: use same key as verifyCode()
      return true;
    }
    return false;
  }


  // Verify OTP
  static Future<bool> verifyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email'); // saved earlier during /send-code
    if (email == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/users/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];

      await prefs.setString('token', token);

      // Fetch user profile (/users/me)
      final meResponse = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (meResponse.statusCode == 200) {
        final user = jsonDecode(meResponse.body);
        await prefs.setString('user', jsonEncode(user));
        return true;
      }
    }

    return false;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData == null) return null;
    return jsonDecode(userData);
  }


  // Get logged-in user info
  static Future<Map<String, dynamic>?> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('DEBUG AuthService: No token found');
      return null;
    }

    print('DEBUG AuthService: Making request to /me endpoint');
    final response = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    print('DEBUG AuthService: Response status: ${response.statusCode}');
    print('DEBUG AuthService: Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('DEBUG AuthService: Parsed data: $data');
      return data;
    }
    return null;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user");
    await prefs.remove("email");
    
    // Note: UserContextService.clearContext() should be called from the UI layer
    // to avoid circular dependencies
  }
  // Fetch all users (for admin)
  static Future<List<dynamic>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$baseUrl/users/all"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Search users (for admin)
  static Future<List<dynamic>> searchUsers(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$baseUrl/users/search?q=$query"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Link user to provider
  static Future<bool> linkUserToProvider(int userId, String providerId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/link-user-provider"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "provider_id": providerId}),
    );

    return response.statusCode == 200;
  }
  // Create guest user 
  static Future<Map<String, dynamic>?> createGuestUser({ String? email, String? phone, String? name, String? providerId, }) async {
     final response = await http.post( 
      Uri.parse("$baseUrl/users/guest"), 
      headers: {"Content-Type": "application/json"}, 
      body: jsonEncode({ if (email != null) "email": email, if (phone != null) "phone": phone, if (name != null) "name": name, if (providerId != null) "provider_id": providerId, }), );
      if (response.statusCode == 200) { return jsonDecode(response.body); } 
      return null; 
  }

  // Admin Management Functions
  static Future<bool> createAdminUser(String email, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/users/admin/create?email=$email${name != null ? '&name=$name' : ''}"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    return response.statusCode == 200;
  }

  static Future<bool> removeAdminUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse("$baseUrl/users/admin/remove?email=$email"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getAdminUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$baseUrl/users/admin/list"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['admins'] ?? [];
    }
    return [];
  }

  // Look up multiple users by their IDs
  static Future<List<dynamic>> lookupUsersByIds(List<int> userIds) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return [];

    final response = await http.post(
      Uri.parse("$baseUrl/users/lookup"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(userIds),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

}
