import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driveon_car_platform/services/auth_service.dart';

enum UserType {
  carOwner,
  provider,
  admin,
  unknown,
}

class UserContext {
  final String? id;
  final String? email;
  final String? name;
  final UserType userType;
  final String? providerId;
  final Map<String, dynamic>? rawData;

  const UserContext({
    this.id,
    this.email,
    this.name,
    required this.userType,
    this.providerId,
    this.rawData,
  });

  bool get isCarOwner => userType == UserType.carOwner;
  bool get isProvider => userType == UserType.provider;
  bool get isAdmin => userType == UserType.admin;
  bool get isUnknown => userType == UserType.unknown;
  //factory constructor is a constructor that is used to create an instance of the class from a map of data,
  //in this case we are creating an instance of the UserContext class from a map of data
  //fromUserData is not an inbuilt method, it is a custom method that we are creating
  factory UserContext.fromUserData(Map<String, dynamic> userData) {
    final providerId = userData['provider_id']?.toString();
    final isAdmin = userData['is_admin'] == true || userData['role'] == 'admin';
    
    // Debug logging
    print('DEBUG Frontend: User data received: $userData');
    print('DEBUG Frontend: is_admin field: ${userData['is_admin']} (type: ${userData['is_admin'].runtimeType})');
    print('DEBUG Frontend: role field: ${userData['role']}');
    print('DEBUG Frontend: isAdmin calculated: $isAdmin');
    
    UserType userType;
    if (isAdmin) {
      userType = UserType.admin;
    } else if (providerId != null && providerId.isNotEmpty) {
      userType = UserType.provider;
    } else {
      userType = UserType.carOwner;
    }
    
    

    return UserContext(
      id: userData['id']?.toString(),
      email: userData['email'],
      name: userData['name'] ?? userData['provider_name'],
      userType: userType,
      providerId: providerId,
      rawData: userData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userType': userType.name,
      'providerId': providerId,
      'rawData': rawData,
    };
  }

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      userType: UserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => UserType.unknown,
      ),
      providerId: json['providerId'],
      rawData: json['rawData'],
    );
  }
}

class UserContextService {
  static const String _userContextKey = 'user_context';
  static UserContext? _currentContext;

  /// Get the current user context
  static UserContext? get currentContext => _currentContext;

  /// Check if user is logged in
  static bool get isLoggedIn => _currentContext != null && _currentContext!.userType != UserType.unknown;

  /// Check if current user is a car owner
  static bool get isCarOwner => _currentContext?.isCarOwner ?? false;

  /// Check if current user is a provider
  static bool get isProvider => _currentContext?.isProvider ?? false;

  /// Check if current user is an admin
  static bool get isAdmin => _currentContext?.isAdmin ?? false;

  /// Get the provider ID if current user is a provider
  static String? get providerId => _currentContext?.providerId;

  /// Initialize user context from stored data or fetch from API
  static Future<UserContext?> initializeContext() async {
    try {
      // First try to load from stored context
      final storedContext = await _loadStoredContext();
      if (storedContext != null) {
        _currentContext = storedContext;
        return storedContext;
      }

      // If no stored context, try to fetch from API
      final userData = await AuthService.getMe();
      if (userData != null) {
        final context = UserContext.fromUserData(userData);
        await _saveContext(context);
        _currentContext = context;
        return context;
      }

      return null;
    } catch (e) {
      debugPrint("Error initializing user context: $e");
      return null;
    }
  }

  /// Update user context with fresh data
  static Future<UserContext?> refreshContext() async {
    try {
      final userData = await AuthService.getMe();
      if (userData != null) {
        final context = UserContext.fromUserData(userData);
        await _saveContext(context);
        _currentContext = context;
        return context;
      }
      return null;
    } catch (e) {
      debugPrint("Error refreshing user context: $e");
      return null;
    }
  }

  /// Clear user context (on logout)
  static Future<void> clearContext() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userContextKey);
    _currentContext = null;
  }

  /// Save context to storage
  static Future<void> _saveContext(UserContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userContextKey, jsonEncode(context.toJson()));
  }

  /// Load context from storage
  static Future<UserContext?> _loadStoredContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextData = prefs.getString(_userContextKey);
      if (contextData != null) {
        final json = jsonDecode(contextData);
        return UserContext.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint("Error loading stored context: $e");
      return null;
    }
  }

  /// Get user display name
  static String getDisplayName() {
    if (_currentContext?.name != null && _currentContext!.name!.isNotEmpty) {
      return _currentContext!.name!;
    }
    if (_currentContext?.email != null) {
      return _currentContext!.email!;
    }
    return "User";
  }

  /// Get user type display string
  static String getUserTypeDisplay() {
    switch (_currentContext?.userType) {
      case UserType.carOwner:
        return "Car Owner";
      case UserType.provider:
        return "Service Provider";
      case UserType.admin:
        return "Administrator";
      case UserType.unknown:
      default:
        return "Unknown";
    }
  }
}
