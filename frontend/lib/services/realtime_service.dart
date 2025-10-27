// frontend/lib/services/realtime_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:driveon_car_platform/services/config.dart';

class RealtimeService {
  static WebSocketChannel? _channel;
  static StreamController<Map<String, dynamic>>? _messageController;
  static Timer? _heartbeatTimer;
  static bool _isConnected = false;

  // Message types
  static const String NEW_POST = 'new_post';
  static const String NEW_COMMENT = 'new_comment';
  static const String NEW_LIKE = 'new_like';
  static const String NEW_FOLLOW = 'new_follow';
  static const String STORY_VIEWED = 'story_viewed';
  static const String TYPING_INDICATOR = 'typing_indicator';
  static const String PRESENCE_UPDATE = 'presence_update';

  /// Connect to WebSocket server
  static Future<bool> connect(int userId) async {
    try {
      final wsUrl = 'ws://${ApiConfig.baseUrl.replaceAll('http://', '').replaceAll('https://', '')}/social/ws/$userId';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      
      // Listen for messages
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            _messageController!.add(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
        },
      );
      
      _isConnected = true;
      _startHeartbeat();
      
      print('WebSocket connected for user $userId');
      return true;
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      return false;
    }
  }

  /// Disconnect from WebSocket server
  static void disconnect() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _messageController?.close();
    _isConnected = false;
    print('WebSocket disconnected');
  }

  /// Get message stream
  static Stream<Map<String, dynamic>>? get messageStream {
    return _messageController?.stream;
  }

  /// Check if connected
  static bool get isConnected => _isConnected;

  /// Send message to server
  static void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }

  /// Send typing indicator
  static void sendTypingIndicator(String postId, int targetUserId) {
    sendMessage({
      'type': TYPING_INDICATOR,
      'post_id': postId,
      'target_user_id': targetUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send story view notification
  static void sendStoryView(String storyId, int storyOwnerId) {
    sendMessage({
      'type': STORY_VIEWED,
      'story_id': storyId,
      'story_owner_id': storyOwnerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Start heartbeat to keep connection alive
  static void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected) {
        sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Listen for specific message types
  static Stream<Map<String, dynamic>> listenFor(String messageType) {
    return _messageController!.stream.where((message) => message['type'] == messageType);
  }

  /// Listen for new posts
  static Stream<Map<String, dynamic>> get newPostsStream {
    return listenFor(NEW_POST);
  }

  /// Listen for new comments
  static Stream<Map<String, dynamic>> get newCommentsStream {
    return listenFor(NEW_COMMENT);
  }

  /// Listen for new likes
  static Stream<Map<String, dynamic>> get newLikesStream {
    return listenFor(NEW_LIKE);
  }

  /// Listen for new follows
  static Stream<Map<String, dynamic>> get newFollowsStream {
    return listenFor(NEW_FOLLOW);
  }

  /// Listen for story views
  static Stream<Map<String, dynamic>> get storyViewsStream {
    return listenFor(STORY_VIEWED);
  }

  /// Listen for typing indicators
  static Stream<Map<String, dynamic>> get typingIndicatorsStream {
    return listenFor(TYPING_INDICATOR);
  }

  /// Listen for presence updates
  static Stream<Map<String, dynamic>> get presenceUpdatesStream {
    return listenFor(PRESENCE_UPDATE);
  }
}

/// Push notification service
class PushNotificationService {
  /// Initialize push notifications
  static Future<bool> initialize() async {
    try {
      // This would integrate with Firebase Cloud Messaging
      // For now, we'll just simulate initialization
      print('Push notifications initialized');
      return true;
    } catch (e) {
      print('Error initializing push notifications: $e');
      return false;
    }
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    try {
      // This would request notification permissions
      // For now, we'll just simulate permission grant
      print('Notification permissions granted');
      return true;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Send local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would show a local notification
      print('Local notification: $title - $body');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  static void handleNotificationTap(Map<String, dynamic> data) {
    try {
      final type = data['type'];
      final postId = data['post_id'];
      final userId = data['user_id'];

      // Navigate based on notification type
      switch (type) {
        case 'new_post':
          // Navigate to post
          print('Navigate to post: $postId');
          break;
        case 'new_comment':
          // Navigate to post with comments
          print('Navigate to post comments: $postId');
          break;
        case 'new_like':
          // Navigate to post
          print('Navigate to liked post: $postId');
          break;
        case 'new_follow':
          // Navigate to user profile
          print('Navigate to user profile: $userId');
          break;
        case 'story_view':
          // Navigate to story
          print('Navigate to story: ${data['story_id']}');
          break;
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }
}

/// Real-time analytics service
class RealtimeAnalyticsService {
  static final Map<String, int> _engagementCounts = {};
  static final Map<String, DateTime> _lastEngagement = {};

  /// Track post engagement
  static void trackPostEngagement(String postId, String engagementType) {
    final key = '${postId}_$engagementType';
    _engagementCounts[key] = (_engagementCounts[key] ?? 0) + 1;
    _lastEngagement[key] = DateTime.now();
  }

  /// Track story view
  static void trackStoryView(String storyId) {
    trackPostEngagement(storyId, 'view');
  }

  /// Track post like
  static void trackPostLike(String postId) {
    trackPostEngagement(postId, 'like');
  }

  /// Track post comment
  static void trackPostComment(String postId) {
    trackPostEngagement(postId, 'comment');
  }

  /// Track post share
  static void trackPostShare(String postId) {
    trackPostEngagement(postId, 'share');
  }

  /// Get engagement analytics
  static Map<String, dynamic> getEngagementAnalytics() {
    return {
      'engagement_counts': Map.from(_engagementCounts),
      'last_engagement': _lastEngagement.map(
        (key, value) => MapEntry(key, value.toIso8601String())
      ),
      'total_engagements': _engagementCounts.values.fold(0, (a, b) => a + b),
    };
  }

  /// Reset analytics
  static void resetAnalytics() {
    _engagementCounts.clear();
    _lastEngagement.clear();
  }
}
