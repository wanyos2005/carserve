// frontend/lib/services/alerts_service.dart
import 'package:driveon_car_platform/services/api_service.dart';

class Alert {
  final String id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final int priority;
  final String? vehicleId;
  final String? policyId;
  final String? bookingId;
  final String? providerId;
  final List<String> channels;
  final String? scheduledAt;
  final String? actionUrl;
  final String? actionText;
  final Map<String, dynamic>? alertMetadata;
  final String status;
  final String? sentAt;
  final String? deliveredAt;
  final String? errorMessage;
  final int retryCount;
  final String createdAt;
  final String updatedAt;

  Alert({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    this.vehicleId,
    this.policyId,
    this.bookingId,
    this.providerId,
    required this.channels,
    this.scheduledAt,
    this.actionUrl,
    this.actionText,
    this.alertMetadata,
    required this.status,
    this.sentAt,
    this.deliveredAt,
    this.errorMessage,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 0,
      vehicleId: json['vehicle_id'],
      policyId: json['policy_id'],
      bookingId: json['booking_id'],
      providerId: json['provider_id'],
      channels: List<String>.from(json['channels'] ?? []),
      scheduledAt: json['scheduled_at'],
      actionUrl: json['action_url'],
      actionText: json['action_text'],
      alertMetadata: json['alert_metadata'],
      status: json['status'] ?? '',
      sentAt: json['sent_at'],
      deliveredAt: json['delivered_at'],
      errorMessage: json['error_message'],
      retryCount: json['retry_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isRead => status == 'delivered';
  bool get isUnread => status == 'pending' || status == 'sent';
  bool get isFailed => status == 'failed';
  
  String get priorityText {
    switch (priority) {
      case 1: return 'Low';
      case 2: return 'Medium';
      case 3: return 'High';
      case 4: return 'Urgent';
      default: return 'Normal';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'insurance_expiry': return 'Insurance Expiry';
      case 'service_due': return 'Service Due';
      case 'app_download_prompt': return 'App Download';
      case 'maintenance_reminder': return 'Maintenance';
      case 'booking_confirmation': return 'Booking';
      case 'payment_reminder': return 'Payment';
      case 'rating_request': return 'Rating Request';
      default: return type.replaceAll('_', ' ').toUpperCase();
    }
  }
}

class AlertPreference {
  final String alertType;
  final bool isEnabled;
  final List<String> channels;

  AlertPreference({
    required this.alertType,
    required this.isEnabled,
    required this.channels,
  });

  factory AlertPreference.fromJson(Map<String, dynamic> json) {
    return AlertPreference(
      alertType: json['alert_type'] ?? '',
      isEnabled: json['is_enabled'] ?? true,
      channels: List<String>.from(json['channels'] ?? ['in_app']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_type': alertType,
      'is_enabled': isEnabled,
      'channels': channels,
    };
  }
}

class AlertsService {
  static const String _baseUrl = '/alerts';

  /// Get alerts for current user
  static Future<List<Alert>> getAlerts({
    int? userId,
    String? alertType,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (alertType != null) queryParams['alert_type'] = alertType;
      if (status != null) queryParams['status'] = status;

      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final url = queryString.isNotEmpty ? '$_baseUrl?$queryString' : _baseUrl;
      print('🔍 Fetching alerts from: $url'); // Debug
      print('🔍 Query params: userId=$userId, alertType=$alertType, status=$status'); // Debug
      final response = await ApiService.get(url);
      
      print('🔍 API Response type: ${response.runtimeType}'); // Debug
      print('🔍 API Response: $response'); // Debug
      
      if (response != null) {
        // Handle both direct list and wrapped response
        List<dynamic> alertsList;
        if (response is List) {
          alertsList = response;
          print('✅ Got ${alertsList.length} alerts from API (direct list)'); // Debug
        } else if (response is Map<String, dynamic>) {
          // Check if response is wrapped in a 'data' field or similar
          if (response.containsKey('data') && response['data'] is List) {
            alertsList = response['data'];
            print('✅ Got ${alertsList.length} alerts from API (wrapped in data)'); // Debug
          } else if (response.containsKey('alerts') && response['alerts'] is List) {
            alertsList = response['alerts'];
            print('✅ Got ${alertsList.length} alerts from API (wrapped in alerts)'); // Debug
          } else {
            // If it's a single alert object, wrap it in a list
            alertsList = [response];
            print('✅ Got 1 alert from API (single object)'); // Debug
          }
        } else {
          print('❌ Unexpected response format: ${response.runtimeType}'); // Debug
          return [];
        }
        
        final alerts = alertsList
            .map((json) => Alert.fromJson(json))
            .toList();
        print('✅ Parsed ${alerts.length} alerts'); // Debug
        return alerts;
      }
      print('⚠️ No response from API'); // Debug
      return [];
    } catch (e) {
      print('❌ Error fetching alerts: $e'); // Debug
      return [];
    }
  }

  /// Get unread alert count for current user
  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiService.get('$_baseUrl/user/me/unread-count');
      if (response != null) {
        return response['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark alert as read
  static Future<bool> markAsRead(String alertId) async {
    try {
      final response = await ApiService.post('$_baseUrl/$alertId/mark-read', {});
      return response != null;
    } catch (e) {
      print('Error marking alert as read: $e');
      return false;
    }
  }

  /// Mark all alerts as read
  static Future<bool> markAllAsRead({int? userId}) async {
    try {
      final alerts = await getAlerts(userId: userId, status: 'pending');
      bool allSuccess = true;
      
      for (final alert in alerts) {
        final success = await markAsRead(alert.id);
        if (!success) allSuccess = false;
      }
      
      return allSuccess;
    } catch (e) {
      print('Error marking all alerts as read: $e');
      return false;
    }
  }

  /// Get alert preferences for current user
  static Future<List<AlertPreference>> getPreferences(int userId) async {
    try {
      final response = await ApiService.get('$_baseUrl/user/$userId/preferences');
      if (response != null) {
        return (response as List)
            .map((json) => AlertPreference.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching alert preferences: $e');
      return [];
    }
  }

  /// Update alert preference
  static Future<bool> upsertPreference({
    required int userId,
    required String alertType,
    required bool isEnabled,
    required List<String> channels,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'alert_type': alertType,
        'is_enabled': isEnabled,
        'channels': channels,
      };
      
      final response = await ApiService.post('$_baseUrl/user/$userId/preferences', data);
      return response != null;
    } catch (e) {
      print('Error updating alert preference: $e');
      return false;
    }
  }

  /// Delete alert
  static Future<bool> deleteAlert(String alertId) async {
    try {
      await ApiService.delete('$_baseUrl/$alertId');
      return true;
    } catch (e) {
      print('Error deleting alert: $e');
      return false;
    }
  }

  /// Get alert by ID
  static Future<Alert?> getAlert(String alertId) async {
    try {
      final response = await ApiService.get('$_baseUrl/$alertId');
      if (response != null) {
        return Alert.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching alert: $e');
      return null;
    }
  }

  /// Filter alerts by type
  static List<Alert> filterByType(List<Alert> alerts, String type) {
    return alerts.where((alert) => alert.type == type).toList();
  }

  /// Filter alerts by status
  static List<Alert> filterByStatus(List<Alert> alerts, String status) {
    return alerts.where((alert) => alert.status == status).toList();
  }

  /// Sort alerts by priority and date
  static List<Alert> sortAlerts(List<Alert> alerts) {
    final sorted = List<Alert>.from(alerts);
    sorted.sort((a, b) {
      // First by priority (higher first)
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      // Then by creation date (newer first)
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  /// Get alerts grouped by type
  static Map<String, List<Alert>> groupByType(List<Alert> alerts) {
    final Map<String, List<Alert>> grouped = {};
    for (final alert in alerts) {
      if (!grouped.containsKey(alert.type)) {
        grouped[alert.type] = [];
      }
      grouped[alert.type]!.add(alert);
    }
    return grouped;
  }
}