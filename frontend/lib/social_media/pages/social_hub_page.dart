import 'package:flutter/material.dart';
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';
import 'package:driveon_car_platform/social_media/widgets/social_post_card.dart';
import 'package:driveon_car_platform/social_media/widgets/featured_post_card.dart';
import 'package:driveon_car_platform/social_media/widgets/suggested_users_section.dart';
import 'package:driveon_car_platform/social_media/services/social_service.dart';
import 'package:driveon_car_platform/social_media/services/realtime_service.dart';
import 'package:driveon_car_platform/social_media/services/content_algorithm_service.dart';
import 'package:driveon_car_platform/social_media/pages/create_post_page.dart';
import 'package:driveon_car_platform/social_media/widgets/comments_section.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/services/alerts_service.dart';
import 'package:driveon_car_platform/services/fcm_service.dart';
import 'package:driveon_car_platform/components/notifications_settings_sheet.dart';
import 'dart:async';

class SocialHubPage extends StatefulWidget {
  const SocialHubPage({super.key});

  @override
  State<SocialHubPage> createState() => _SocialHubPageState();
}
//tickerProviderStateMixin is used to create a tab controller that can be used to switch between tabs
class _SocialHubPageState extends State<SocialHubPage> with TickerProviderStateMixin {
  late TabController _tabController;

  // Social content data
  List<SocialPost> _feedPosts = [];
  SocialPost? _featuredPost;
  List<SocialUser> _suggestedUsers = [];
  List<String> _trendingHashtags = [];
  bool _isLoading = true;
  String? _error;

  // Real-time properties
  bool _isRealtimeConnected = false;
  StreamSubscription? _realtimeSubscription;

  // Notification properties
  int _unreadAlertCount = 0;
  List<Alert> _recentAlerts = [];

  // Feed optimization properties
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update active tab styling
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Initialize user context first, then load content and real-time service
    _initializeUserContext().then((_) {
      _loadSocialContent().then((_) {
        _initializeRealtimeService();
        _loadNotifications();
        _initializeFCM(); // Initialize FCM for push notifications
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  /// Initialize user context before loading content
  Future<void> _initializeUserContext() async {
    try {
      // Ensure user context is initialized
      await UserContextService.initializeContext();
      // User context initialized
    } catch (e) {
      // Error initializing user context
      // Continue without user context - will use defaults
    }
  }

  Future<void> _loadSocialContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMorePosts = true;
    });

    try {
      // Load content in parallel with individual error handling
      final results = await Future.wait([
        _safeGetFeedPosts(),
        _safeGetSuggestedUsers(),
        _safeGetTrendingHashtags(),
      ]);

      final rawPosts = results[0] as List<SocialPost>;
      final suggestedUsers = results[1] as List<SocialUser>;
      final trendingHashtags = results[2] as List<String>;

      // Apply TikTok-style algorithm to rank posts
      final userId = await _getCurrentUserId();
      final algorithmPosts = ContentAlgorithmService.rankPosts(
        rawPosts,
        userId: userId,
        userInterests: _getUserInterests(),
        userHashtags: _getUserHashtags(),
      );

      // Create a featured post from the first post (if available)
      SocialPost? featuredPost;
      if (algorithmPosts.isNotEmpty) {
        final firstPost = algorithmPosts.first;
        featuredPost = SocialPost(
          id: firstPost.id,
          userId: firstPost.userId,
          providerId: firstPost.providerId,
          content: firstPost.content,
          mediaUrls: firstPost.mediaUrls,
          hashtags: firstPost.hashtags,
          type: firstPost.type,
          createdAt: firstPost.createdAt,
          updatedAt: firstPost.updatedAt,
          stats: firstPost.stats,
          isSponsored: true, // Mark as featured/sponsored
          sponsoredBy: "DriveOn",
          status: firstPost.status,
        );
      }

      setState(() {
        _feedPosts = algorithmPosts;
        _featuredPost = featuredPost;
        _suggestedUsers = suggestedUsers;
        _trendingHashtags = trendingHashtags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Get user interests for algorithm
  List<String> _getUserInterests() {
    try {
      final context = UserContextService.currentContext;
      if (context?.rawData != null) {
        // Try to get interests from user profile data
        final interests = context!.rawData!['interests'];
        if (interests is List) {
          return interests.cast<String>();
        }
        
        // If user is a provider, add provider-specific interests
        if (context.isProvider) {
          return ['car maintenance', 'auto repair', 'service provider', 'business'];
        }
        
        // If user is a car owner, add car owner interests
        if (context.isCarOwner) {
          return ['car maintenance', 'auto repair', 'sustainability', 'electric vehicles'];
        }
      }
    } catch (e) {
      // Error getting user interests
    }
    
    // Default interests based on user type
    final context = UserContextService.currentContext;
    if (context?.isProvider == true) {
      return ['car maintenance', 'auto repair', 'service provider', 'business'];
    } else {
      return ['car maintenance', 'auto repair', 'sustainability', 'electric vehicles'];
    }
  }

  /// Get user hashtags for algorithm
  List<String> _getUserHashtags() {
    try {
      final context = UserContextService.currentContext;
      if (context?.rawData != null) {
        // Try to get hashtags from user profile data
        final hashtags = context!.rawData!['hashtags'];
        if (hashtags is List) {
          return hashtags.cast<String>();
        }
        
        // If user is a provider, add provider-specific hashtags
        if (context.isProvider) {
          return ['DriveOn', 'ServiceProvider', 'NairobiCars', 'AutoRepair'];
        }
        
        // If user is a car owner, add car owner hashtags
        if (context.isCarOwner) {
          return ['DriveOn', 'CarMaintenance', 'NairobiCars', 'AutoRepair'];
        }
      }
    } catch (e) {
      // Error getting user hashtags
    }
    
    // Default hashtags based on user type
    final context = UserContextService.currentContext;
    if (context?.isProvider == true) {
      return ['DriveOn', 'ServiceProvider', 'NairobiCars', 'AutoRepair'];
    } else {
      return ['DriveOn', 'CarMaintenance', 'NairobiCars', 'AutoRepair'];
    }
  }

  /// Safe wrapper for getting feed posts
  Future<List<SocialPost>> _safeGetFeedPosts() async {
    try {
      final posts = await SocialService.getFeedPosts();
      // Limit initial load to improve performance
      return posts.take(20).toList();
    } catch (e) {
      return [];
    }
  }


  /// Safe wrapper for getting suggested users
  Future<List<SocialUser>> _safeGetSuggestedUsers() async {
    try {
      return await SocialService.getSuggestedUsers();
    } catch (e) {
      return [];
    }
  }

  /// Safe wrapper for getting trending hashtags
  Future<List<String>> _safeGetTrendingHashtags() async {
    try {
      return await SocialService.getTrendingHashtags();
    } catch (e) {
      return [];
    }
  }

  /// Load notifications and alerts
  Future<void> _loadNotifications() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      // Load unread count and recent alerts
      final unreadCount = await AlertsService.getUnreadCount();
      final recentAlerts = await AlertsService.getAlerts(limit: 10);

      setState(() {
        _unreadAlertCount = unreadCount;
        _recentAlerts = recentAlerts;
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  /// Initialize real-time WebSocket connection
  Future<void> _initializeRealtimeService() async {
    try {
      // Get actual user ID from storage or auth service
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _isRealtimeConnected = false;
        return;
      }

      // Connect to WebSocket with error handling
      _isRealtimeConnected = await RealtimeService.connect(userId);
      
      if (_isRealtimeConnected) {
        _setupRealtimeListeners();
      }
    } catch (e) {
      // Continue without real-time features
      _isRealtimeConnected = false;
    }
  }

  /// Initialize FCM for push notifications
  Future<void> _initializeFCM() async {
    try {
      // Check if FCM is already initialized
      if (FCMService.fcmToken != null) {
        print('✅ FCM already initialized with token: ${FCMService.fcmToken}');
        return;
      }
      
      // Initialize FCM service
      final success = await FCMService.initialize();
      if (success) {
        print('✅ FCM initialized successfully in Social Hub');
      } else {
        print('❌ FCM initialization failed in Social Hub');
      }
    } catch (e) {
      print('❌ Error initializing FCM in Social Hub: $e');
    }
  }

  /// Get current user ID from user context service
  Future<int?> _getCurrentUserId() async {
    try {
      // First try to get from current context
      final currentContext = UserContextService.currentContext;
      if (currentContext?.id != null) {
        return int.tryParse(currentContext!.id!);
      }

      // If no current context, try to initialize it
      final context = await UserContextService.initializeContext();
      if (context?.id != null) {
        return int.tryParse(context!.id!);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Setup real-time listeners for live updates
  void _setupRealtimeListeners() {
    // Listen for all real-time messages with null safety
    _realtimeSubscription = RealtimeService.messageStream?.listen(
      (message) {
        _handleRealtimeMessage(message);
      },
      onError: (error) {
        _isRealtimeConnected = false;
      },
      onDone: () {
        _isRealtimeConnected = false;
      },
    );
  }

  /// Handle incoming real-time messages
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

  /// Handle new post real-time update
  void _handleNewPost(Map<String, dynamic> data) {
    setState(() {
      final newPost = SocialPost.fromJson(data['post']);
      _feedPosts.insert(0, newPost);
    });
    
    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New post from ${data['user_name'] ?? 'User'}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _scrollToPost(data['post_id']),
        ),
      ),
    );
  }

  /// Handle new comment real-time update
  void _handleNewComment(Map<String, dynamic> data) {
    setState(() {
      final postId = data['post_id'];
      final postIndex = _feedPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _feedPosts[postIndex] = _updatePostCommentCount(_feedPosts[postIndex], 1);
      }
    });
  }

  /// Handle new like real-time update
  void _handleNewLike(Map<String, dynamic> data) {
    setState(() {
      final postId = data['post_id'];
      final postIndex = _feedPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _feedPosts[postIndex] = _updatePostLikeCount(_feedPosts[postIndex], 1);
      }
    });
  }

  /// Handle new follow real-time update
  void _handleNewFollow(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['follower_name'] ?? 'Someone'} started following you!'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigateToProfile(data['follower_id']),
        ),
      ),
    );
  }

  /// Handle story viewed real-time update
  void _handleStoryViewed(Map<String, dynamic> data) {
    // Update story view count if needed
  }

  /// Handle presence update real-time update
  void _handlePresenceUpdate(Map<String, dynamic> data) {
    // Update online/offline indicators if needed
  }

  /// Show real-time notification
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

  /// Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final postId = data['post_id'];
    final userId = data['user_id'];

    switch (type) {
      case 'new_post':
        _scrollToPost(postId);
        break;
      case 'new_comment':
        _showComments(SocialPost(id: postId, userId: 0, content: '', mediaUrls: [], hashtags: [], type: PostType.text, createdAt: DateTime.now(), updatedAt: DateTime.now(), stats: PostStats(likes: 0, comments: 0, shares: 0, views: 0, isLikedByUser: false, isSharedByUser: false), isSponsored: false, status: PostStatus.published));
        break;
      case 'new_like':
        _scrollToPost(postId);
        break;
      case 'new_follow':
        _navigateToProfile(userId);
        break;
    }
  }

  /// Scroll to specific post
  void _scrollToPost(String postId) {
    // Implementation for scrolling to specific post
  }

  /// Navigate to user profile
  void _navigateToProfile(int userId) {
    // Implementation for navigating to user profile
  }

  /// Update post comment count
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

  /// Update post like count
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
    _scrollController.dispose();
    _realtimeSubscription?.cancel();
    RealtimeService.disconnect();
    super.dispose();
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newPosts = await SocialService.getFeedPosts(page: _currentPage + 1);
      
      if (newPosts.isEmpty) {
        _hasMorePosts = false;
      } else {
        setState(() {
          _feedPosts.addAll(newPosts);
          _currentPage++;
        });
      }
    } catch (e) {
      // Handle error silently for pagination
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[50]!,
              Colors.blue[50]!,
              Colors.cyan[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Create Post Button
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreatePostPage()),
                        );
                        if (result == true) {
                          _loadSocialContent();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.red[600]!.withOpacity(0.3),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.auto_awesome, color: Colors.purple[600], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getWelcomeMessage(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Settings Button with Notification Badge
                    GestureDetector(
                      onTap: () => _showSettings(),
                      child: Stack(
                        children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                            child: Icon(Icons.settings, color: Colors.grey[600]),
                          ),
                          if (_unreadAlertCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red[600],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  _unreadAlertCount > 99 ? '99+' : _unreadAlertCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMainFeedTab(),
                    _buildExploreTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80, // Increased overall height
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: const BoxDecoration(), // Remove default indicator
                  labelColor: Colors.red[600],
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
          fontSize: 13, // Increased from 12
                  ),
                  unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13, // Increased from 12
                  ),
                  isScrollable: false,
                  tabAlignment: TabAlignment.fill,
        tabs: List.generate(2, (index) {
          final isActive = _tabController.index == index;
          
                    return Tab(
            height: 80, // Increased to match container height
                      child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getTabIcon(index),
                      size: 26, // Increased size
                      color: isActive ? Colors.red[600] : Colors.grey[600],
                    ),
                  const SizedBox(height: 4), // Increased spacing
                            Text(
                              _getTabText(index),
                              style: TextStyle(
                      fontSize: 11, // Increased from 10
                      fontWeight: isActive 
                                    ? FontWeight.bold 
                          : FontWeight.w600,
                      color: isActive ? Colors.red[600] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
      ),
    );
  }

  Widget _buildMainFeedTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_feedPosts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadSocialContent,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(0),
        itemCount: _getFeedItemCount() + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == _getFeedItemCount()) {
            return _buildLoadingMoreIndicator();
          }

          // Show featured post first
          if (index == 0 && _featuredPost != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FeaturedPostCard(
                post: _featuredPost!,
                onLike: () => _toggleLike(_featuredPost!),
              ),
            );
          }

          // Show suggested users after 5 posts (accounting for featured post)
          final suggestedUsersIndex = _featuredPost != null ? 6 : 5;
          if (index == suggestedUsersIndex && _suggestedUsers.isNotEmpty) {
            return SuggestedUsersSection(
              users: _suggestedUsers,
              onTap: (user) => _toggleFollow(user),
            );
          }
          
          // Adjust post index to account for featured post and suggested users section
          int postIndex = index;
          if (_featuredPost != null) {
            postIndex -= 1; // Account for featured post
          }
          if (index > suggestedUsersIndex) {
            postIndex -= 1; // Account for suggested users section
          }
          
          if (postIndex >= 0 && postIndex < _feedPosts.length) {
            final post = _feedPosts[postIndex];
          return RepaintBoundary(
            key: ValueKey(post.id),
              child: SocialPostCard(
                post: post,
                onLike: () => _toggleLike(post),
                onComment: () => _showComments(post),
                onShare: () => _sharePost(post),
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
          ),
            const SizedBox(height: 16),
          Text(
            'Loading your feed...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
                ),
            ),
          ],
        ),
      );
    }

  Widget _buildErrorState() {
      return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load your feed. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSocialContent,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
          ),
        ],
      ),
        ),
      );
    }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Your feed is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by creating your first post or following some users to see their content here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostPage()),
                );
                if (result == true) {
                  _loadSocialContent();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
              ),
            ),
            const SizedBox(width: 12),
          Text(
              'Loading more posts...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getFeedItemCount() {
    int count = _feedPosts.length;
    if (_featuredPost != null) {
      count += 1; // Add 1 for featured post
    }
    if (_suggestedUsers.isNotEmpty && _feedPosts.length >= 5) {
      count += 1; // Add 1 for suggested users section
    }
    return count;
  }

  




  Widget _buildExploreTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600]),
              const SizedBox(width: 12),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search mobility topics, users, challenges...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Trending Topics
        Text(
          "Trending Topics",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingHashtags.isNotEmpty
            ? _trendingHashtags.take(6).map((tag) => _buildTrendingTag("#$tag", _getTagColor(tag))).toList()
            : [
                _buildTrendingTag("#ElectricVehicles", Colors.green),
                _buildTrendingTag("#CarMaintenance", Colors.blue),
                _buildTrendingTag("#SustainableMobility", Colors.purple),
                _buildTrendingTag("#NairobiTraffic", Colors.orange),
                _buildTrendingTag("#CarFreeLife", Colors.teal),
                _buildTrendingTag("#AutoCare", Colors.red),
              ],
        ),
        const SizedBox(height: 20),

        // Featured Users
        Text(
          "Featured Users",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        if (_suggestedUsers.isNotEmpty)
          ..._suggestedUsers.take(3).map((user) => _buildFeaturedUser(
            user.username,
            user.bio ?? (user.isProvider ? "Service Provider" : "Car Enthusiast"),
            user.isProvider ? Colors.blue : Colors.purple,
          ))
        else ...[
          _buildFeaturedUser("EcoWarrior_KE", "Sustainability advocate", Colors.green),
          _buildFeaturedUser("CarGuru_Nairobi", "Auto expert", Colors.blue),
          _buildFeaturedUser("MobilityFuture", "EV enthusiast", Colors.purple),
        ],
      ],
    );
  }





  Widget _buildTrendingTag(String tag, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFeaturedUser(String username, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(Icons.person, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Follow", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Helper methods for enhanced social features

  // Interaction methods

  Future<void> _toggleLike(SocialPost post) async {
    final success = await SocialService.toggleLike(post.id);
    if (success) {
      // Track analytics
      RealtimeAnalyticsService.trackPostLike(post.id);
      
      // Track engagement for algorithm
      final userId = await _getCurrentUserId();
      if (userId != null) {
        ContentAlgorithmService.trackEngagement(
          postId: post.id,
          interactionType: InteractionType.like,
          userId: userId,
        );
      }
      
      setState(() {
        // Update the post's like status locally
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





  Future<void> _toggleFollow(SocialUser user) async {
    final success = await SocialService.toggleFollow(user.id.toString());
    if (success) {
      setState(() {
        // Update the user's follow status locally
        final index = _suggestedUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _suggestedUsers[index] = SocialUser(
            id: user.id,
            username: user.username,
            displayName: user.displayName,
            profileImageUrl: user.profileImageUrl,
            bio: user.bio,
            isVerified: user.isVerified,
            isProvider: user.isProvider,
            providerId: user.providerId,
            stats: user.stats,
            isFollowing: !user.isFollowing,
            isFollowedBy: user.isFollowedBy,
          );
        }
      });
    }
  }

  void _showComments(SocialPost post) async {
    // Load comments for this post
    final comments = await SocialService.getPostComments(post.id);
    
    // Track engagement for algorithm
    final userId = await _getCurrentUserId();
    if (userId != null) {
      ContentAlgorithmService.trackEngagement(
        postId: post.id,
        interactionType: InteractionType.comment,
        userId: userId,
      );
    }
    
    // Show comments bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSection(
        postId: post.id,
        initialComments: comments,
        onCommentCountChanged: (newCount) {
          // Update the post's comment count in the UI
          setState(() {
            final postIndex = _feedPosts.indexWhere((p) => p.id == post.id);
            if (postIndex != -1) {
              _feedPosts[postIndex] = SocialPost(
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
                  comments: newCount,
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
          });
        },
      ),
    );
  }

  Future<void> _sharePost(SocialPost post) async {
    final success = await SocialService.sharePost(post.id);
    if (success) {
      // Track analytics
      RealtimeAnalyticsService.trackPostShare(post.id);
      
      // Track engagement for algorithm
      final userId = await _getCurrentUserId();
      if (userId != null) {
        ContentAlgorithmService.trackEngagement(
          postId: post.id,
          interactionType: InteractionType.share,
          userId: userId,
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully!')),
      );
    }
  }

  // Helper method to get color for hashtags
  Color _getTagColor(String tag) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.red,
      Colors.pink,
      Colors.indigo,
    ];
    
    // Use hash of tag to consistently assign colors
    final hash = tag.hashCode;
    return colors[hash.abs() % colors.length];
  }

  /// Get welcome message for header
  String _getWelcomeMessage() {
    try {
      final context = UserContextService.currentContext;
      if (context != null) {
        final displayName = UserContextService.getDisplayName();
        
        if (context.isProvider) {
          return "Welcome, $displayName";
        } else if (context.isCarOwner) {
          return "Hi $displayName!";
        } else {
          return "Mobility Hub";
        }
      }
    } catch (e) {
      // Error getting welcome message
    }
    
    return "Mobility Hub";
  }


  // Helper methods for tab bar
  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.explore;
      default:
        return Icons.home;
    }
  }

  String _getTabText(int index) {
    switch (index) {
      case 0:
        return "Feed";
      case 1:
        return "Explore";
      default:
        return "Feed";
    }
  }

  /// Show settings popover
  void _showSettings() {
    showNotificationsSettingsSheet(
      context: context,
      unreadAlertCount: _unreadAlertCount,
      recentAlerts: _recentAlerts,
      onRefreshNotifications: _loadNotifications,
    );
  }

}

