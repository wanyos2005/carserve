import 'package:driveon_car_platform/services/api_service.dart';
import 'package:driveon_car_platform/services/fcm_service.dart';

class AlertsService {
  static Future<List<dynamic>> getPreferences(int userId) async {
    final res = await ApiService.get('/notifications/preferences/$userId');
    return (res is List) ? res : <dynamic>[];
  }

  static Future<dynamic> upsertPreference({
    required int userId,
    required String alertType, // e.g., 'insurance_expiry', 'service_due'
    required bool isEnabled,
    List<String> channels = const ['in_app'], // 'email','sms','in_app','push','whatsapp'
    String frequency = 'immediate',
    String? quietHoursStart,
    String? quietHoursEnd,
    String timezone = 'Africa/Nairobi',
    int minPriority = 1,
    bool batchAlerts = false,
  }) async {
    final body = {
      'user_id': userId,
      'alert_type': alertType,
      'is_enabled': isEnabled,
      'channels': channels,
      'frequency': frequency,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'timezone': timezone,
      'min_priority': minPriority,
      'batch_alerts': batchAlerts,
    };
    return ApiService.post('/notifications/preferences', body);
  }

  // Alerts inbox APIs
  static Future<List<dynamic>> getAlerts({
    required int userId,
    String? type, // e.g., 'insurance_expiry'
    String? status, // e.g., 'delivered'
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'user_id': userId.toString(),
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (type != null) 'alert_type': type,
      if (status != null) 'status': status,
    };
    final res = await ApiService.get('/alerts/', query: query);
    return (res is List) ? res : <dynamic>[];
  }

  static Future<bool> markRead(String alertId) async {
    final res = await ApiService.put('/alerts/$alertId', {
      // Fallback: some backends use PATCH /mark-read, support both below
    });
    // If PUT didn't work, try dedicated endpoint
    if (res == null) {
      final ok = await ApiService.post('/alerts/$alertId/mark-read', {});
      return ok != null;
    }
    return true;
  }

  static Future<int> getUnreadCount(int userId) async {
    final res = await ApiService.get('/alerts/user/$userId/unread-count');
    return (res != null && res['unread_count'] is int) ? res['unread_count'] as int : 0;
  }

  // FCM token management
  static Future<bool> registerFCMToken(int userId, String fcmToken) async {
    try {
      final response = await ApiService.post('/users/$userId/fcm-token', {'fcm_token': fcmToken});
      return response != null;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFCMToken(int userId) async {
    try {
      await ApiService.delete('/users/$userId/fcm-token');
      return true;
    } catch (e) {
      return false;
    }
  }
}


