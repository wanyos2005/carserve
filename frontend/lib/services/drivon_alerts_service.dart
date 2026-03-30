// lib/services/drivon_alerts_service.dart
// API client for Drivon Alerts pillar: broadcast alerts + incident reports.

import 'package:driveon_car_platform/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class BroadcastAlert {
  final String id;
  final String title;
  final String message;
  final String type;
  final int priority;
  final String status;
  final String? source;
  final String? actionUrl;
  final String? actionText;
  final String? expiresAt;
  final String createdAt;

  BroadcastAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    this.source,
    this.actionUrl,
    this.actionText,
    this.expiresAt,
    required this.createdAt,
  });

  factory BroadcastAlert.fromJson(Map<String, dynamic> json) {
    return BroadcastAlert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      priority: json['priority'] ?? 2,
      status: json['status'] ?? 'active',
      source: json['source'],
      actionUrl: json['action_url'],
      actionText: json['action_text'],
      expiresAt: json['expires_at'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class IncidentReport {
  final String id;
  final int userId;
  final String incidentType;
  final String title;
  final String description;
  final String? latitude;
  final String? longitude;
  final String? locationText;
  final List<String> mediaUrls;
  final String status;
  final String? adminNotes;
  final String createdAt;

  IncidentReport({
    required this.id,
    required this.userId,
    required this.incidentType,
    required this.title,
    required this.description,
    this.latitude,
    this.longitude,
    this.locationText,
    required this.mediaUrls,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? 0,
      incidentType: json['incident_type'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      locationText: json['location_text'],
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      status: json['status'] ?? 'submitted',
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class DrivonAlertsService {
  static const String _broadcastBase = '/api/alerts/broadcast-alerts';
  static const String _incidentsBase = '/api/alerts/incidents';

  // ── Broadcast alerts (public, user-facing) ───────────────────────────────

  /// Fetch currently active broadcast alerts. Optionally filter by [alertType]
  /// (weather | security | safety | route_alert | fleet_alert).
  static Future<List<BroadcastAlert>> getActiveAlerts({String? alertType}) async {
    try {
      final query = <String, String>{};
      if (alertType != null) query['alert_type'] = alertType;
      final response = await ApiService.get('$_broadcastBase/active', query: query);
      if (response is List) {
        return response.map((e) => BroadcastAlert.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Incident reports (user-facing) ────────────────────────────────────────

  /// Submit a new incident report from the user.
  static Future<Map<String, dynamic>> submitIncident({
    required int userId,
    required String incidentType,
    required String title,
    required String description,
    String? latitude,
    String? longitude,
    String? locationText,
    List<String>? mediaUrls,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'incident_type': incidentType,
        'title': title,
        'description': description,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationText != null) 'location_text': locationText,
        'media_urls': mediaUrls ?? [],
      };
      final response = await ApiService.post('$_incidentsBase/', body);
      if (response == null) return {'success': false, 'error': 'Server error'};
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch the current user's submitted incident reports.
  static Future<List<IncidentReport>> getMyIncidents(int userId) async {
    try {
      final response = await ApiService.get(
        '$_incidentsBase/mine',
        query: {'user_id': userId.toString()},
      );
      if (response is List) {
        return response.map((e) => IncidentReport.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Admin: broadcast alert management ─────────────────────────────────────

  static Future<List<BroadcastAlert>> adminListAlerts({String? status}) async {
    try {
      final query = <String, String>{};
      if (status != null) query['status'] = status;
      final response = await ApiService.get('$_broadcastBase/', query: query);
      if (response is List) {
        return response.map((e) => BroadcastAlert.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> adminCreateAlert({
    required String title,
    required String message,
    required String type,
    int priority = 2,
    List<String> channels = const ['in_app', 'push'],
    String? source,
    String? actionUrl,
    String? actionText,
    String? expiresAt,
  }) async {
    try {
      final body = {
        'title': title,
        'message': message,
        'type': type,
        'priority': priority,
        'channels': channels,
        if (source != null) 'source': source,
        if (actionUrl != null) 'action_url': actionUrl,
        if (actionText != null) 'action_text': actionText,
        if (expiresAt != null) 'expires_at': expiresAt,
      };
      final response = await ApiService.post('$_broadcastBase/', body);
      if (response == null) return {'success': false, 'error': 'Server error'};
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> adminPublishAlert(String alertId) async {
    try {
      final response = await ApiService.post('$_broadcastBase/$alertId/publish', {});
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> adminCancelAlert(String alertId) async {
    try {
      final response = await ApiService.patch(
        '$_broadcastBase/$alertId',
        {'status': 'cancelled'},
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Admin: incident management ─────────────────────────────────────────────

  static Future<List<IncidentReport>> adminListIncidents({String? status}) async {
    try {
      final query = <String, String>{};
      if (status != null) query['status'] = status;
      final response = await ApiService.get('$_incidentsBase/', query: query);
      if (response is List) {
        return response.map((e) => IncidentReport.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> adminUpdateIncident(
    String reportId, {
    String? status,
    String? adminNotes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (adminNotes != null) body['admin_notes'] = adminNotes;
      final response = await ApiService.patch('$_incidentsBase/$reportId', body);
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Phone update ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updatePhone(String phone) async {
    try {
      final response = await ApiService.patch('/users/me/phone', {}, query: {'phone': phone});
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
