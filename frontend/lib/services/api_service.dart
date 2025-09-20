// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseGatewayUrl = "http://192.168.0.107:8000";// nginx gateway "http://192.168.0.107:8000"; peter , "http://192.168.2.116:8000"; alex


  // Get token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Generic GET
  static Future<dynamic> get(String path) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseGatewayUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Generic POST
  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
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
      return jsonDecode(response.body);
    }
    return null;
  }

  // Generic DELETE
  static Future<bool> delete(String path) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseGatewayUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
