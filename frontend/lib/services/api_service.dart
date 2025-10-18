// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car_platform/services/user_context_service.dart';

class ApiService {
  static const String baseGatewayUrl = "http://152.70.28.112"; 
  // Production gateway:
  // Oracle Cloud VM -> "http://152.70.28.112"

  // --- TOKEN HANDLER ---
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // --- USER CONTEXT INTEGRATION ---
  static String? getCurrentUserId() {
    return UserContextService.currentContext?.id;
  }

  static bool get isLoggedIn => UserContextService.isLoggedIn;

  // --- GENERIC GET ---
  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final token = await _getToken();
    Uri uri = Uri.parse("$baseGatewayUrl$path").replace(queryParameters: query);

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }
    print("GET $path failed: ${response.statusCode} - ${response.body}");
    return null;
  }

  // --- GENERIC POST ---
  static Future<dynamic> post(String path, dynamic body) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseGatewayUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }
    print("POST $path failed: ${response.statusCode} - ${response.body}");
    return null;
  }

  // --- GENERIC PUT ---
  static Future<dynamic> put(String path, dynamic body) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse("$baseGatewayUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }
    print("PUT $path failed: ${response.statusCode} - ${response.body}");
    return null;
  }

  // --- GENERIC DELETE ---
  static Future<bool> delete(String path) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseGatewayUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    print("DELETE $path failed: ${response.statusCode} - ${response.body}");
    return false;
  }
}
