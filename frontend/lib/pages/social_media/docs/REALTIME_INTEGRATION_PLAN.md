# 🔌 **Real-time Integration Plan for Social Hub**

## **Current Status: ❌ NO Real-time Integration**

The `social_hub_page.dart` currently only uses:
- ✅ `SocialService` for API calls (HTTP requests)
- ❌ **Missing**: `RealtimeService` for WebSocket connections
- ❌ **Missing**: Live updates, notifications, presence
- ❌ **Missing**: Real-time analytics

---

## **🎯 Integration Strategy**

### **1. Initialize Real-time Service** 🔌
```dart
// In _SocialHubPageState.initState()
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 4, vsync: this);
  _tabController.addListener(() {
    setState(() {});
  });
  
  // Initialize real-time service
  _initializeRealtimeService();
  _loadSocialContent();
}

Future<void> _initializeRealtimeService() async {
  // Connect to WebSocket
  await RealtimeService.connect(1); // Use actual user ID
  
  // Listen for real-time updates
  _setupRealtimeListeners();
}
```

### **2. Real-time Listeners** 📡
```dart
void _setupRealtimeListeners() {
  // New posts
  RealtimeService.newPostsStream.listen((data) {
    setState(() {
      // Add new post to feed
      final newPost = SocialPost.fromJson(data['post']);
      _feedPosts.insert(0, newPost);
    });
  });

  // New comments
  RealtimeService.newCommentsStream.listen((data) {
    setState(() {
      // Update comment count for specific post
      final postId = data['post_id'];
      final postIndex = _feedPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _feedPosts[postIndex] = _updatePostCommentCount(_feedPosts[postIndex], 1);
      }
    });
  });

  // New likes
  RealtimeService.newLikesStream.listen((data) {
    setState(() {
      // Update like count for specific post
      final postId = data['post_id'];
      final postIndex = _feedPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _feedPosts[postIndex] = _updatePostLikeCount(_feedPosts[postIndex], 1);
      }
    });
  });

  // Story views
  RealtimeService.storyViewsStream.listen((data) {
    // Update story view count
    print('Story viewed: ${data['story_id']}');
  });

  // Presence updates
  RealtimeService.presenceUpdatesStream.listen((data) {
    // Show online/offline indicators
    print('User ${data['user_id']} is ${data['status']}');
  });
}
```

### **3. Real-time Analytics Integration** 📊
```dart
void _trackUserEngagement(String postId, String action) {
  // Track engagement for analytics
  RealtimeAnalyticsService.trackPostEngagement(postId, action);
  
  // Send to backend for trending calculations
  RealtimeService.sendMessage({
    'type': 'engagement_track',
    'post_id': postId,
    'action': action,
    'user_id': 1, // Current user ID
    'timestamp': DateTime.now().toIso8601String(),
  });
}

// Update existing methods
Future<void> _toggleLike(SocialPost post) async {
  final success = await SocialService.toggleLike(post.id);
  if (success) {
    // Track analytics
    _trackUserEngagement(post.id, 'like');
    
    setState(() {
      // Update UI
      final index = _feedPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        // ... existing update logic
      }
    });
  }
}
```

### **4. Real-time Notifications** 🔔
```dart
void _setupNotificationHandlers() {
  // Listen for push notifications
  RealtimeService.messageStream?.listen((message) {
    if (message['type'] == 'notification') {
      _showRealtimeNotification(message);
    }
  });
}

void _showRealtimeNotification(Map<String, dynamic> data) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(data['message']),
      action: SnackBarAction(
        label: 'View',
        onPressed: () => _handleNotificationTap(data),
      ),
    ),
  );
}
```

---

## **🚀 Complete Integration Example**

### **Updated `_SocialHubPageState` Class:**
```dart
class _SocialHubPageState extends State<SocialHubPage> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Existing properties
  List<SocialPost> _feedPosts = [];
  List<SocialStory> _stories = [];
  List<SocialUser> _suggestedUsers = [];
  List<String> _trendingHashtags = [];
  bool _isLoading = true;
  String? _error;
  
  // NEW: Real-time properties
  bool _isRealtimeConnected = false;
  StreamSubscription? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    
    // Initialize real-time service
    _initializeRealtimeService();
    _loadSocialContent();
  }

  Future<void> _initializeRealtimeService() async {
    try {
      // Connect to WebSocket
      _isRealtimeConnected = await RealtimeService.connect(1);
      
      if (_isRealtimeConnected) {
        _setupRealtimeListeners();
        print('✅ Real-time service connected');
      } else {
        print('❌ Failed to connect to real-time service');
      }
    } catch (e) {
      print('Error initializing real-time service: $e');
    }
  }

  void _setupRealtimeListeners() {
    // Listen for all real-time messages
    _realtimeSubscription = RealtimeService.messageStream?.listen((message) {
      _handleRealtimeMessage(message);
    });
  }

  void _handleRealtimeMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'new_post':
        _handleNewPost(message);
        break;
      case 'new_comment':
        _handleNewComment(message);
        break;
      case 'new_like':
        _handleNewLike(message);
        break;
      case 'new_follow':
        _handleNewFollow(message);
        break;
      case 'story_viewed':
        _handleStoryViewed(message);
        break;
      case 'presence_update':
        _handlePresenceUpdate(message);
        break;
      case 'notification':
        _showRealtimeNotification(message);
        break;
    }
  }

  void _handleNewPost(Map<String, dynamic> data) {
    setState(() {
      final newPost = SocialPost.fromJson(data['post']);
      _feedPosts.insert(0, newPost);
    });
    
    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New post from ${data['user_name']}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _scrollToPost(data['post_id']),
        ),
      ),
    );
  }

  void _handleNewComment(Map<String, dynamic> data) {
    setState(() {
      final postId = data['post_id'];
      final postIndex = _feedPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _feedPosts[postIndex] = _updatePostCommentCount(_feedPosts[postIndex], 1);
      }
    });
  }

  void _handleNewLike(Map<String, dynamic> data) {
    setState(() {
      final postId = data['post_id'];
      final postIndex = _feedPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _feedPosts[postIndex] = _updatePostLikeCount(_feedPosts[postIndex], 1);
      }
    });
  }

  // Helper methods for updating posts
  SocialPost _updatePostCommentCount(SocialPost post, int increment) {
    return SocialPost(
      id: post.id,
      userId: post.userId,
      providerId: post.providerId,
      content: post.content,
      mediaUrls: post.mediaUrls,
      hashtags: post.hashtags,
      type: post.type,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      stats: PostStats(
        likes: post.stats.likes,
        comments: post.stats.comments + increment,
        shares: post.stats.shares,
        views: post.stats.views,
        isLikedByUser: post.stats.isLikedByUser,
        isSharedByUser: post.stats.isSharedByUser,
      ),
      isSponsored: post.isSponsored,
      sponsoredBy: post.sponsoredBy,
      status: post.status,
    );
  }

  SocialPost _updatePostLikeCount(SocialPost post, int increment) {
    return SocialPost(
      id: post.id,
      userId: post.userId,
      providerId: post.providerId,
      content: post.content,
      mediaUrls: post.mediaUrls,
      hashtags: post.hashtags,
      type: post.type,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      stats: PostStats(
        likes: post.stats.likes + increment,
        comments: post.stats.comments,
        shares: post.stats.shares,
        views: post.stats.views,
        isLikedByUser: post.stats.isLikedByUser,
        isSharedByUser: post.stats.isSharedByUser,
      ),
      isSponsored: post.isSponsored,
      sponsoredBy: post.sponsoredBy,
      status: post.status,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeSubscription?.cancel();
    RealtimeService.disconnect();
    super.dispose();
  }

  // Update existing methods to include real-time tracking
  Future<void> _toggleLike(SocialPost post) async {
    final success = await SocialService.toggleLike(post.id);
    if (success) {
      // Track analytics
      RealtimeAnalyticsService.trackPostLike(post.id);
      
      setState(() {
        final index = _feedPosts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          final updatedStats = PostStats(
            likes: post.stats.isLikedByUser 
              ? post.stats.likes - 1 
              : post.stats.likes + 1,
            comments: post.stats.comments,
            shares: post.stats.shares,
            views: post.stats.views,
            isLikedByUser: !post.stats.isLikedByUser,
            isSharedByUser: post.stats.isSharedByUser,
          );
          _feedPosts[index] = SocialPost(
            id: post.id,
            userId: post.userId,
            providerId: post.providerId,
            content: post.content,
            mediaUrls: post.mediaUrls,
            hashtags: post.hashtags,
            type: post.type,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            stats: updatedStats,
            isSponsored: post.isSponsored,
            sponsoredBy: post.sponsoredBy,
            status: post.status,
          );
        }
      });
    }
  }

  // Add real-time connection indicator
  Widget _buildConnectionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isRealtimeConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isRealtimeConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _isRealtimeConnected ? 'Live' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## **🎯 Benefits of Integration**

### **✅ Real-time Features Added:**
1. **Live Updates**: New posts appear instantly
2. **Live Notifications**: Comments, likes, follows in real-time
3. **Presence Tracking**: See who's online
4. **Analytics**: Track engagement in real-time
5. **WebSocket Connection**: Persistent real-time connection

### **✅ User Experience Improvements:**
1. **Instant Feedback**: Actions update immediately
2. **Live Notifications**: Never miss important updates
3. **Real-time Analytics**: Trending content updates live
4. **Connection Status**: Users know if they're connected

---

## **🚀 Implementation Steps**

1. **Add Real-time Service Import**:
   ```dart
   import 'package:car_platform/services/realtime_service.dart';
   ```

2. **Initialize in `initState()`**:
   ```dart
   _initializeRealtimeService();
   ```

3. **Add Real-time Listeners**:
   ```dart
   _setupRealtimeListeners();
   ```

4. **Update Existing Methods**:
   ```dart
   // Add analytics tracking to all interactions
   RealtimeAnalyticsService.trackPostEngagement(postId, action);
   ```

5. **Add Connection Indicator**:
   ```dart
   // Show in header
   _buildConnectionIndicator()
   ```

---

## **🎉 Result: Fully Real-time Social Hub!**

After integration, the social hub will have:
- ✅ **Live WebSocket connection**
- ✅ **Real-time post updates**
- ✅ **Live notifications**
- ✅ **Analytics tracking**
- ✅ **Presence indicators**
- ✅ **Connection status**

**The social hub will become a truly real-time, engaging social platform!** 🚀
