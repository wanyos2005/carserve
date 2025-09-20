//1. auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://192.168.0.100:8000";// gateway

  static Future<bool> login(String passcode) async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString("last_registered_email");

  if (email == null) return false;

  final response = await http.post(
    Uri.parse("$baseUrl/users/login"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": email,
      "passcode": passcode,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await prefs.setString("token", data["access_token"]);
    return true;
  }

  return false;
}

  static Future<bool> register(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password, "role": role}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}
