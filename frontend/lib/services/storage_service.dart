import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized storage service to eliminate SharedPreferences repetition
class StorageService {
  static SharedPreferences? _prefs;
  
  /// Initialize SharedPreferences instance (call once at app startup)
  static Future<void> initialize() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }
  
  /// Get SharedPreferences instance (cached)
  static Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
  
  // Token management
  static Future<String?> getToken() async {
    final prefs = await _prefsInstance;
    return prefs.getString('token');
  }
  
  static Future<void> setToken(String token) async {
    final prefs = await _prefsInstance;
    await prefs.setString('token', token);
  }
  
  static Future<void> clearToken() async {
    final prefs = await _prefsInstance;
    await prefs.remove('token');
  }
  
  // User data management
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _prefsInstance;
    final userData = prefs.getString('user');
    if (userData == null) return null;
    return jsonDecode(userData);
  }
  
  static Future<void> setUser(Map<String, dynamic> user) async {
    final prefs = await _prefsInstance;
    await prefs.setString('user', jsonEncode(user));
  }
  
  static Future<void> clearUser() async {
    final prefs = await _prefsInstance;
    await prefs.remove('user');
  }
  
  // Email management
  static Future<String?> getEmail() async {
    final prefs = await _prefsInstance;
    return prefs.getString('email');
  }
  
  static Future<void> setEmail(String email) async {
    final prefs = await _prefsInstance;
    await prefs.setString('email', email);
  }
  
  static Future<void> clearEmail() async {
    final prefs = await _prefsInstance;
    await prefs.remove('email');
  }
  
  // Context management
  static Future<void> setContext(String key, Map<String, dynamic> context) async {
    final prefs = await _prefsInstance;
    await prefs.setString(key, jsonEncode(context));
  }
  
  static Future<Map<String, dynamic>?> getContext(String key) async {
    final prefs = await _prefsInstance;
    final contextData = prefs.getString(key);
    if (contextData == null) return null;
    return jsonDecode(contextData);
  }
  
  static Future<void> clearContext(String key) async {
    final prefs = await _prefsInstance;
    await prefs.remove(key);
  }
  
  // Clear all authentication data
  static Future<void> clearAllAuth() async {
    final prefs = await _prefsInstance;
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('email');
    await prefs.remove('user_context');
  }
}
