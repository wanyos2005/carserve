import 'package:flutter/material.dart';
import 'package:car_platform/models/social_content_models.dart';
import 'package:car_platform/services/social_service.dart';
import 'package:car_platform/services/realtime_service.dart';
import 'package:car_platform/pages/social_media/create_post_page.dart';
import 'package:car_platform/widgets/comments_section.dart';
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
  List<SocialStory> _stories = [];
  List<SocialUser> _suggestedUsers = [];
  List<String> _trendingHashtags = [];
  bool _isLoading = true;
  String? _error;

  // Real-time properties
  bool _isRealtimeConnected = false;
  StreamSubscription? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update active tab styling
    });
    
    // Initialize real-time service
    _initializeRealtimeService();
    _loadSocialContent();
  }

  Future<void> _loadSocialContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load content in parallel with individual error handling
      final results = await Future.wait([
        _safeGetFeedPosts(),
        _safeGetActiveStories(),
        _safeGetSuggestedUsers(),
        _safeGetTrendingHashtags(),
      ]);

      setState(() {
        _feedPosts = results[0] as List<SocialPost>;
        _stories = results[1] as List<SocialStory>;
        _suggestedUsers = results[2] as List<SocialUser>;
        _trendingHashtags = results[3] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Safe wrapper for getting feed posts
  Future<List<SocialPost>> _safeGetFeedPosts() async {
    try {
      return await SocialService.getFeedPosts();
    } catch (e) {
      print('Error fetching feed posts: $e');
      return [];
    }
  }

  /// Safe wrapper for getting active stories
  Future<List<SocialStory>> _safeGetActiveStories() async {
    try {
      return await SocialService.getActiveStories();
    } catch (e) {
      print('Error fetching stories: $e');
      return [];
    }
  }

  /// Safe wrapper for getting suggested users
  Future<List<SocialUser>> _safeGetSuggestedUsers() async {
    try {
      return await SocialService.getSuggestedUsers();
    } catch (e) {
      print('Error fetching suggested users: $e');
      return [];
    }
  }

  /// Safe wrapper for getting trending hashtags
  Future<List<String>> _safeGetTrendingHashtags() async {
    try {
      return await SocialService.getTrendingHashtags();
    } catch (e) {
      print('Error fetching trending hashtags: $e');
      return [];
    }
  }

  /// Initialize real-time WebSocket connection
  Future<void> _initializeRealtimeService() async {
    try {
      // Connect to WebSocket with error handling
      _isRealtimeConnected = await RealtimeService.connect(1); // Use actual user ID
      
      if (_isRealtimeConnected) {
        _setupRealtimeListeners();
        print('✅ Real-time service connected');
      } else {
        print('❌ Failed to connect to real-time service - using offline mode');
        // Continue without real-time features
      }
    } catch (e) {
      print('Error initializing real-time service: $e');
      // Continue without real-time features
      _isRealtimeConnected = false;
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
        print('Real-time listener error: $error');
        _isRealtimeConnected = false;
      },
      onDone: () {
        print('Real-time listener closed');
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
    print('Story viewed: ${data['story_id']}');
    // Update story view count if needed
  }

  /// Handle presence update real-time update
  void _handlePresenceUpdate(Map<String, dynamic> data) {
    print('User ${data['user_id']} is ${data['status']}');
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
    print('Navigate to post: $postId');
  }

  /// Navigate to user profile
  void _navigateToProfile(int userId) {
    // Implementation for navigating to user profile
    print('Navigate to user profile: $userId');
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
    _realtimeSubscription?.cancel();
    RealtimeService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
          
          // Refresh content if a post was created
          if (result == true) {
            _loadSocialContent();
          }
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                    Icon(Icons.auto_awesome, color: Colors.purple[600], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Mobility Hub",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Real-time connection indicator
                    _buildConnectionIndicator(),
                    const SizedBox(width: 8),
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
                      child: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Tab Bar with Red Ring Light Effect
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.red.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: const BoxDecoration(), // Remove default indicator
                  labelColor: Colors.red[600],
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  isScrollable: false,
                  tabAlignment: TabAlignment.fill,
                  tabs: List.generate(4, (index) {
                    return Tab(
                      height: 60, // Fixed height to prevent overflow
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: _tabController.index == index
                              ? Border.all(
                                  color: Colors.red[600]!,
                                  width: 1,
                                )
                              : null,
                          boxShadow: _tabController.index == index
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getTabIcon(index),
                              size: 18,
                              color: _tabController.index == index 
                                  ? Colors.red[600] 
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getTabText(index),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: _tabController.index == index 
                                    ? FontWeight.bold 
                                    : FontWeight.w500,
                                color: _tabController.index == index 
                                    ? Colors.red[600] 
                                    : Colors.grey[600],
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
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInstagramFeedTab(),
                    _buildStoriesTab(),
                    _buildCommunityTab(),
                    _buildExploreTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramFeedTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Error loading content: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSocialContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSocialContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(0),
        itemCount: _feedPosts.length,
        itemBuilder: (context, index) {
          final post = _feedPosts[index];
          return _buildInstagramPost(post);
        },
      ),
    );
  }

  Widget _buildStoriesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Error loading content: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSocialContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSocialContent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stories Section
          if (_stories.isNotEmpty) ...[
            Text(
              "Stories",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _stories.length,
                itemBuilder: (context, index) {
                  final story = _stories[index];
                  return _buildStoryItem(story);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Featured Post
          if (_feedPosts.isNotEmpty) ...[
            Text(
              "Featured",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildFeaturedPost(_feedPosts.first),
            const SizedBox(height: 20),
          ],

          // Content Grid
          Text(
            "Explore Content",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStoryCard("Oil Change DIY", "Learn the basics", Colors.blue, Icons.oil_barrel),
              _buildStoryCard("Electric Dreams", "EV adoption journey", Colors.green, Icons.electric_car),
              _buildStoryCard("Car-Free Life", "Sustainable mobility", Colors.purple, Icons.directions_walk),
              _buildStoryCard("Mechanic Tips", "Expert advice", Colors.orange, Icons.build),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCommunityTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadSocialContent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickAction("Create Post", Icons.add_circle, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction("Join Group", Icons.group_add, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction("Find Events", Icons.event, Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Suggested Users
          if (_suggestedUsers.isNotEmpty) ...[
            Text(
              "Suggested Users",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedUsers.length,
                itemBuilder: (context, index) {
                  final user = _suggestedUsers[index];
                  return _buildSuggestedUserCard(user);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Community Posts Feed
          Text(
            "Community Feed",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          // Real posts from feed
          if (_feedPosts.isNotEmpty)
            ..._feedPosts.take(5).map((post) => _buildCommunityPostFromData(post))
          else
            // Fallback to static content if no real posts
            ..._buildStaticCommunityPosts(),
        ],
      ),
    );
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

  Widget _buildStoryCard(String title, String subtitle, Color color, IconData icon) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPost(String group, String content, String time, String likes, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.group, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                likes,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Spacer(),
              Icon(Icons.comment_outlined, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Icon(Icons.share_outlined, color: Colors.grey[600], size: 20),
            ],
          ),
        ],
      ),
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

  // New helper methods for enhanced social features

  Widget _buildInstagramPost(SocialPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: post.isProvider ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                  child: Icon(
                    post.isProvider ? Icons.business : Icons.person,
                    color: post.isProvider ? Colors.blue : Colors.purple,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'user_${post.userId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.isProvider) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "PRO",
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
          
          // Media content
          if (post.mediaUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.0, // Square aspect ratio like Instagram
              child: Image.network(
                post.mediaUrls.first,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(
                      post.type == PostType.video ? Icons.videocam : Icons.image,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
          
          // Actions (like, comment, share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(post),
                  child: Icon(
                    post.stats.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                    color: post.stats.isLikedByUser ? Colors.red : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _showComments(post),
                  child: Icon(Icons.comment_outlined, color: Colors.grey[600], size: 24),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _sharePost(post),
                  child: Icon(Icons.send_outlined, color: Colors.grey[600], size: 24),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Icon(Icons.bookmark_border, color: Colors.grey[600], size: 24),
                ),
              ],
            ),
          ),
          
          // Likes count
          if (post.stats.likes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${post.stats.likes} likes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'user_${post.userId} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: post.content,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Comments count
          if (post.stats.comments > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: GestureDetector(
                onTap: () => _showComments(post),
                child: Text(
                  'View all ${post.stats.comments} comments',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          
          // Hashtags
          if (post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: post.hashtags.take(3).map((tag) => Text(
                  '#$tag',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                )).toList(),
              ),
            ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStoryItem(SocialStory story) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _viewStory(story),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.isViewed 
                  ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[600]!])
                  : LinearGradient(colors: [Colors.purple[400]!, Colors.blue[400]!]),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: story.mediaUrl != null
                ? ClipOval(
                    child: Image.network(
                      story.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          story.type == StoryType.video ? Icons.videocam : Icons.image,
                          color: Colors.white,
                          size: 24,
                        );
                      },
                    ),
                  )
                : Icon(
                    story.type == StoryType.video ? Icons.videocam : Icons.image,
                    color: Colors.white,
                    size: 24,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'user_${story.userId}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPost(SocialPost post) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.red[400]!],
        ),
      ),
      child: Stack(
        children: [
          if (post.mediaUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                post.mediaUrls.first,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.red[400]!],
                      ),
                    ),
                  );
                },
              ),
            ),
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.isSponsored ? "SPONSORED" : "TRENDING",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: post.isSponsored ? Colors.blue : Colors.red,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.content.length > 60 
                    ? '${post.content.substring(0, 60)}...' 
                    : post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: const Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'user_${post.userId}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _toggleLike(post),
                      child: Icon(
                        post.stats.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                        color: post.stats.isLikedByUser ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text("${post.stats.likes}", style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Interaction methods
  Future<void> _viewStory(SocialStory story) async {
    await SocialService.viewStory(story.id);
    // Track analytics
    RealtimeAnalyticsService.trackStoryView(story.id);
    // Navigate to story viewer
    // This would open a full-screen story viewer
  }

  Future<void> _toggleLike(SocialPost post) async {
    final success = await SocialService.toggleLike(post.id);
    if (success) {
      // Track analytics
      RealtimeAnalyticsService.trackPostLike(post.id);
      
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

  // Community tab helper methods
  Widget _buildSuggestedUserCard(SocialUser user) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _toggleFollow(user),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: user.isProvider ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
              child: user.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          user.isProvider ? Icons.business : Icons.person,
                          color: user.isProvider ? Colors.blue : Colors.purple,
                          size: 24,
                        );
                      },
                    ),
                  )
                : Icon(
                    user.isProvider ? Icons.business : Icons.person,
                    color: user.isProvider ? Colors.blue : Colors.purple,
                    size: 24,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.username.length > 8 ? '${user.username.substring(0, 8)}...' : user.username,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (user.isProvider)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "PRO",
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityPostFromData(SocialPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: post.isProvider ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                child: Icon(
                  post.isProvider ? Icons.business : Icons.person,
                  color: post.isProvider ? Colors.blue : Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'user_${post.userId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isProvider) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "PRO",
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatTimeAgo(post.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.isSponsored)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "SPONSORED",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.mediaUrls.first,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
          if (post.hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: post.hashtags.take(3).map((tag) => Text(
                '#$tag',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(post),
                child: Row(
                  children: [
                    Icon(
                      post.stats.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                      color: post.stats.isLikedByUser ? Colors.red : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${post.stats.likes}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showComments(post),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "${post.stats.comments}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _sharePost(post),
                child: Icon(Icons.share_outlined, color: Colors.grey[600], size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStaticCommunityPosts() {
    return [
      _buildCommunityPost(
        "Nairobi Car Enthusiasts",
        "Just got my car serviced at AutoCare Kenya. Amazing service!",
        "2 hours ago",
        "45 likes",
        Colors.blue,
      ),
      _buildCommunityPost(
        "Eco-Mobility Kenya",
        "Biked to work today instead of driving. Feeling great! 🌱",
        "4 hours ago",
        "23 likes",
        Colors.green,
      ),
      _buildCommunityPost(
        "Electric Vehicle Kenya",
        "Tesla Model 3 spotted in Westlands. The future is here! ⚡",
        "6 hours ago",
        "67 likes",
        Colors.purple,
      ),
    ];
  }

  // Utility methods
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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

  // Helper methods for tab bar
  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.auto_stories;
      case 2:
        return Icons.groups;
      case 3:
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
        return "Stories";
      case 2:
        return "Community";
      case 3:
        return "Explore";
      default:
        return "Feed";
    }
  }

  /// Build real-time connection indicator
  Widget _buildConnectionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isRealtimeConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: (_isRealtimeConnected ? Colors.green : Colors.red).withOpacity(0.3),
            offset: const Offset(0, 2),
          ),
        ],
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
