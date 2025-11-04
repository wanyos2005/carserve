import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:driveon_car_platform/services/api_service.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/components/rating_dialog.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  // Optional navigation hook for deep links from notifications
  static Future<void> Function(String actionUrl)? onNavigate;

  /// Initialize Firebase Cloud Messaging
  static Future<bool> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        if (kDebugMode) {
          print('FCM Token: $_fcmToken');
        }

        // Register token with backend
        await _registerTokenWithBackend();

        // Set up message handlers
        _setupMessageHandlers();

        return true;
      } else {
        if (kDebugMode) {
          print('FCM permission denied');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM initialization error: $e');
      }
      return false;
    }
  }

  /// Register FCM token with backend
  static Future<void> _registerTokenWithBackend() async {
    if (_fcmToken == null) return;

    final userId = UserContextService.currentContext?.id;
    if (userId == null) return;

    try {
      await ApiService.post('/users/$userId/fcm-token', {
        'fcm_token': _fcmToken,
      });
      if (kDebugMode) {
        print('FCM token registered with backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register FCM token: $e');
      }
    }
  }

  /// Set up message handlers
  static void _setupMessageHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received foreground message: ${message.notification?.title}');
      }
      _handleForegroundMessage(message);
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped: ${message.notification?.title}');
      }
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App opened from notification: ${message.notification?.title}');
        }
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification or in-app notification
    // For now, just print - you can integrate with your notification system
    if (kDebugMode) {
      print('Foreground message: ${message.notification?.title} - ${message.notification?.body}');
    }
  }

  /// Handle notification taps
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final actionUrl = data['action_url'];
    
    if (actionUrl != null && actionUrl.isNotEmpty) {
      // Check if this is a rating request and handle it directly
      final ratingParams = parseRatingActionUrl(actionUrl);
      if (ratingParams != null) {
        final userIdStr = UserContextService.currentContext?.id;
        if (userIdStr != null) {
          final userId = int.tryParse(userIdStr);
          if (userId != null) {
            // Use the navigation handler if available (which should have BuildContext)
            if (onNavigate != null) {
              try {
                await onNavigate!(actionUrl);
                return;
              } catch (_) {}
            }
            // Fallback: try to use navigator key if available
            if (kDebugMode) {
              print('Rating action URL detected: $actionUrl');
              print('Note: onNavigate callback should be set up to show rating dialog');
            }
            return;
          }
        }
      }
      
      // For other action URLs, use the navigation handler if provided
      if (onNavigate != null) {
        try {
          await onNavigate!(actionUrl);
          return;
        } catch (_) {}
      }
      if (kDebugMode) {
        print('Navigate to: $actionUrl');
      }
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Refresh FCM token
  static Future<void> refreshToken() async {
    _fcmToken = await _messaging.getToken();
    await _registerTokenWithBackend();
  }

  /// Unsubscribe from FCM
  static Future<void> unsubscribe() async {
    final userId = UserContextService.currentContext?.id;
    if (userId != null) {
      try {
        await ApiService.delete('/users/$userId/fcm-token');
        if (kDebugMode) {
          print('FCM token removed from backend');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to remove FCM token: $e');
        }
      }
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.notification?.title}');
  }
  // Handle background message processing here
}
