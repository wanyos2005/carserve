import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://192.168.0.107:8000/users";//.107 -Kelly

  // Send OTP
  static Future<bool> sendCode(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/send-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_email", email);
      return true;
    }
    return false;
  }

  // Verify OTP
  static Future<bool> verifyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("last_email");
    if (email == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/verify-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString("token", data["access_token"]);
      return true;
    }
    return false;
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
}
