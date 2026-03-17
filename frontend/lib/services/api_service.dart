// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/services/storage_service.dart';
import 'package:driveon_car_platform/services/config.dart';

class ApiService {
  static const String baseGatewayUrl = ApiConfig.baseUrl;
  // Production gateway:
 

  // --- TOKEN HANDLER ---
  static Future<String?> _getToken() async {
    return await StorageService.getToken();
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

    print('🌐 API GET: $uri'); // Debug
    print('🌐 Headers: Authorization=${token != null ? "Bearer ***" : "null"}'); // Debug

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    print('🌐 Response status: ${response.statusCode}'); // Debug
    print('🌐 Response body length: ${response.body.length}'); // Debug
    if (response.statusCode >= 400) {
      print('❌ API Error: ${response.statusCode} - ${response.body}'); // Debug
    }

    // Clear invalid tokens on 401 (unauthorized)
    if (response.statusCode == 401) {
      print('⚠️ 401 Unauthorized - clearing stored token');
      await StorageService.clearToken();
      await StorageService.clearUser();
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }
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

    print('🌐 API POST: $baseGatewayUrl$path → ${response.statusCode}');
    if (response.statusCode >= 400) print('🌐 POST error body: ${response.body}');

    // Clear invalid tokens on 401 (unauthorized)
    if (response.statusCode == 401) {
      print('⚠️ 401 Unauthorized - clearing stored token');
      await StorageService.clearToken();
      await StorageService.clearUser();
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }
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
    return null;
  }

  // --- GENERIC DELETE ---
  static Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async {
    final token = await _getToken();
    Uri uri = Uri.parse("$baseGatewayUrl$path");
    
    // Add query parameters if provided
    if (query != null) {
      final queryParams = query.map((key, value) => MapEntry(key, value.toString()));
      uri = uri.replace(queryParameters: queryParams);
    }
    
    final response = await http.delete(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    // Clear invalid tokens on 401 (unauthorized)
    if (response.statusCode == 401) {
      print('⚠️ 401 Unauthorized - clearing stored token');
      await StorageService.clearToken();
      await StorageService.clearUser();
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : true;
    }
    return null;
  }

  // --- MULTIPART UPLOAD ---
  static Future<dynamic> uploadMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse("$baseGatewayUrl$path");
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Fields
    fields?.forEach((k, v) => request.fields[k] = v);

    // Files (default field key is the map key)
    if (files != null) {
      for (final entry in files.entries) {
        final f = entry.value;
        request.files.add(await http.MultipartFile.fromPath(entry.key, f.path));
      }
    }

    // (debug logs removed)

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    // (debug logs removed)

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }
    return null;
  }
}
