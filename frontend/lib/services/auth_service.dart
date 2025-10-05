import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://192.168.0.107:8000/users";//.107 -Kelly

  // Send OTP
  // Send OTP
  static Future<bool> sendCode(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/send-code"),
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
      Uri.parse('$baseUrl/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];

      await prefs.setString('token', token);

      // Fetch user profile (/me)
      final meResponse = await http.get(
        Uri.parse('$baseUrl/me'),
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
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
  // Fetch all users (for admin)
  static Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(Uri.parse("$baseUrl/all"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Link user to provider
  static Future<bool> linkUserToProvider(int userId, String providerId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/link-user-provider"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "provider_id": providerId}),
    );

    return response.statusCode == 200;
  }

}
