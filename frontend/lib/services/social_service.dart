// Social Service for DriveOn Platform
// Handles all social hub interactions, content management, and user engagement

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:driveon_car_platform/services/config.dart';
import 'package:driveon_car_platform/models/social_content_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocialService {
  static const String baseUrl = ApiConfig.baseUrl;

  // ==================== POSTS ====================

  /// Get feed posts with pagination
  static Future<List<SocialPost>> getFeedPosts({
    int page = 1,
    int limit = 20,
    String? category,
    String? hashtag,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null) queryParams['category'] = category;
      if (hashtag != null) queryParams['hashtag'] = hashtag;

      final uri = Uri.parse('$baseUrl/social/posts/feed').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final posts = (data['posts'] as List<dynamic>)
            .map((post) => SocialPost.fromJson(post))
            .toList();
        return posts;
      }
    } catch (e) {
      print('Error fetching feed posts: $e');
    }
    
    // Return mock data for development
    return _getMockFeedPosts();
  }

  /// Create a new post
  static Future<SocialPost?> createPost({
    required String content,
    List<String> mediaUrls = const [],
    List<String> hashtags = const [],
    PostType type = PostType.text,
    String? providerId,
    bool isSponsored = false,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/social/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'media_urls': mediaUrls,
          'hashtags': hashtags,
          'type': type.name,
          'provider_id': providerId,
          'is_sponsored': isSponsored,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SocialPost.fromJson(data['post']);
      }
    } catch (e) {
      print('Error creating post: $e');
    }
    return null;
  }

  /// Like/Unlike a post
  static Future<bool> toggleLike(String postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/social/interactions/likes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'post_id': postId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  /// Like/Unlike a comment
  static Future<bool> toggleCommentLike(String commentId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/social/interactions/likes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'comment_id': commentId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling comment like: $e');
      return false;
    }
  }

  /// Share a post
  static Future<bool> sharePost(String postId, {String? message}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/social/posts/$postId/share'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': message}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sharing post: $e');
      return false;
    }
  }

  // ==================== COMMENTS ====================

  /// Get comments for a post
  static Future<List<SocialComment>> getPostComments(String postId, {int page = 1, int limit = 20}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/social/interactions/comments/$postId?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data as List<dynamic>)
            .map((comment) => SocialComment.fromJson(comment))
            .toList();
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
    return [];
  }

  /// Add a comment to a post
  static Future<SocialComment?> addComment(String postId, String content, {String? parentId}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/social/interactions/comments?post_id=$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'parent_id': parentId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SocialComment.fromJson(data);
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
    return null;
  }

  /// Update a comment
  static Future<SocialComment?> updateComment(String commentId, String content) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/social/interactions/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SocialComment.fromJson(data);
      }
    } catch (e) {
      print('Error updating comment: $e');
    }
    return null;
  }

  /// Delete a comment
  static Future<bool> deleteComment(String commentId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/social/interactions/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // ==================== USERS ====================

  /// Get user profile
  static Future<SocialUser?> getUserProfile(String userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/social/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SocialUser.fromJson(data['user']);
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

  /// Follow/Unfollow a user
  static Future<bool> toggleFollow(String userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/social/users/$userId/follow'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling follow: $e');
      return false;
    }
  }

  /// Get user's posts
  static Future<List<SocialPost>> getUserPosts(String userId, {int page = 1}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/social/users/$userId/posts?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['posts'] as List<dynamic>)
            .map((post) => SocialPost.fromJson(post))
            .toList();
      }
    } catch (e) {
      print('Error fetching user posts: $e');
    }
    return [];
  }

  // ==================== STORIES ====================

  /// Get active stories
  static Future<List<SocialStory>> getActiveStories() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/social/stories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['stories'] as List<dynamic>)
            .map((story) => SocialStory.fromJson(story))
            .toList();
      }
    } catch (e) {
      print('Error fetching stories: $e');
    }
    
    // Return mock data for development
    return _getMockStories();
  }

  /// Create a story
  static Future<SocialStory?> createStory({
    required String content,
    String? mediaUrl,
    StoryType type = StoryType.image,
    String? providerId,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/social/stories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'media_url': mediaUrl,
          'type': type.name,
          'provider_id': providerId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SocialStory.fromJson(data['story']);
      }
    } catch (e) {
      print('Error creating story: $e');
    }
    return null;
  }

  /// Mark story as viewed
  static Future<bool> viewStory(String storyId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/social/stories/$storyId/view'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error viewing story: $e');
      return false;
    }
  }

  // ==================== SEARCH & DISCOVERY ====================

  /// Search posts by hashtag or content
  static Future<List<SocialPost>> searchPosts(String query, {int page = 1}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/social/search/posts?q=$query&page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['posts'] as List<dynamic>)
            .map((post) => SocialPost.fromJson(post))
            .toList();
      }
    } catch (e) {
      print('Error searching posts: $e');
    }
    return [];
  }

  /// Get trending hashtags
  static Future<List<String>> getTrendingHashtags() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/social/trending/hashtags'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['hashtags'] ?? []);
      }
    } catch (e) {
      print('Error fetching trending hashtags: $e');
    }
    
    // Return mock data for development
    return _getMockTrendingHashtags();
  }

  /// Get suggested users to follow
  static Future<List<SocialUser>> getSuggestedUsers() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/social/users/suggested'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['users'] as List<dynamic>)
            .map((user) => SocialUser.fromJson(user))
            .toList();
      }
    } catch (e) {
      print('Error fetching suggested users: $e');
    }
    
    // Return mock data for development
    return _getMockSuggestedUsers();
  }

  // ==================== PROVIDER INTEGRATION ====================

  /// Get provider content
  static Future<List<SocialPost>> getProviderContent(String providerId, {int page = 1}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/social/providers/$providerId/content?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['posts'] as List<dynamic>)
            .map((post) => SocialPost.fromJson(post))
            .toList();
      }
    } catch (e) {
      print('Error fetching provider content: $e');
    }
    return [];
  }

  /// Create sponsored post
  static Future<SocialPost?> createSponsoredPost({
    required String content,
    required String providerId,
    List<String> mediaUrls = const [],
    List<String> hashtags = const [],
    double budget = 0.0,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/social/posts/sponsored'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'provider_id': providerId,
          'media_urls': mediaUrls,
          'hashtags': hashtags,
          'budget': budget,
          'is_sponsored': true,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SocialPost.fromJson(data['post']);
      }
    } catch (e) {
      print('Error creating sponsored post: $e');
    }
    return null;
  }

  // ==================== UTILITY METHODS ====================

  /// Get authentication token
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  /// Upload media file to Cloudflare R2
  static Future<String?> uploadMedia(File file, {String folder = "posts"}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/social/media/upload'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      // Add folder parameter
      request.fields['folder'] = folder;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['success']) {
        return jsonData['url'];
      } else {
        print('Upload failed: ${jsonData['detail'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  /// Upload multiple media files
  static Future<List<String>> uploadMultipleMedia(List<File> files, {String folder = "posts"}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/social/media/upload-multiple'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add files
      for (var file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            file.path,
          ),
        );
      }

      // Add folder parameter
      request.fields['folder'] = folder;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['success']) {
        return (jsonData['uploaded_files'] as List)
            .map((file) => file['url'] as String)
            .toList();
      } else {
        print('Upload failed: ${jsonData['errors'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      print('Error uploading multiple media: $e');
      return [];
    }
  }

  /// Get content analytics for providers
  static Future<Map<String, dynamic>?> getContentAnalytics(String providerId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/social/providers/$providerId/analytics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching content analytics: $e');
    }
    return null;
  }

  // ==================== MOCK DATA METHODS ====================

  static List<SocialPost> _getMockFeedPosts() {
    return [
      SocialPost(
        id: '6911920e-f4c0-42b2-9db2-14d2e29e0aee',
        userId: 6,
        providerId: '9e5e7b0a-273f-4d34-8914-2c174e720a65',
        content: '🔧 Puncture repair completed in 15 minutes! Quality patch work that will last. Don\'t let a small puncture become a big problem. #PunctureRepair #TyreService #QuickService #DriveOn',
        mediaUrls: ['https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&h=600&fit=crop'],
        hashtags: ['PunctureRepair', 'TyreService', 'QuickService', 'DriveOn'],
        type: PostType.image,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        stats: PostStats(likes: 27, comments: 13, shares: 4, views: 335, isLikedByUser: false, isSharedByUser: false),
        isSponsored: true,
        sponsoredBy: '9e5e7b0a-273f-4d34-8914-2c174e720a65',
        status: PostStatus.published,
      ),
      SocialPost(
        id: 'ab1b88ab-4f03-4e94-84e6-40b98e8b7bd7',
        userId: 6,
        providerId: '9e5e7b0a-273f-4d34-8914-2c174e720a65',
        content: '🛞 Wheel alignment in progress! Proper alignment ensures even tyre wear and better fuel efficiency. Don\'t ignore those steering vibrations! #WheelAlignment #TyreService #TyreMax #DriveOn',
        mediaUrls: ['https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&h=600&fit=crop'],
        hashtags: ['WheelAlignment', 'TyreService', 'TyreMax', 'DriveOn'],
        type: PostType.image,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        stats: PostStats(likes: 26, comments: 4, shares: 9, views: 229, isLikedByUser: false, isSharedByUser: false),
        isSponsored: false,
        status: PostStatus.published,
      ),
      SocialPost(
        id: 'd421bc44-460c-464a-a911-706b116d5fef',
        userId: 5,
        providerId: '66fd2721-f5ec-421a-82db-147621ff05f4',
        content: '🧽 Interior deep clean transformation! From dusty to pristine in just 2 hours. Your car\'s interior deserves the same care as the exterior. #InteriorClean #CarDetailing #AutoSpa #DriveOn',
        mediaUrls: ['https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop', 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop'],
        hashtags: ['InteriorClean', 'CarDetailing', 'AutoSpa', 'DriveOn'],
        type: PostType.carousel,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        stats: PostStats(likes: 27, comments: 10, shares: 2, views: 78, isLikedByUser: false, isSharedByUser: false),
        isSponsored: true,
        sponsoredBy: '66fd2721-f5ec-421a-82db-147621ff05f4',
        status: PostStatus.published,
      ),
    ];
  }

  static List<SocialStory> _getMockStories() {
    return [
      SocialStory(
        id: 'story_1',
        userId: 6,
        providerId: '9e5e7b0a-273f-4d34-8914-2c174e720a65',
        content: 'Behind the scenes: Puncture repair in progress! ✨',
        mediaUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=300&h=300&fit=crop',
        type: StoryType.image,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        expiresAt: DateTime.now().add(const Duration(hours: 23)),
        isViewed: false,
        stats: StoryStats(views: 45, interactions: 12),
      ),
      SocialStory(
        id: 'story_2',
        userId: 5,
        providerId: '66fd2721-f5ec-421a-82db-147621ff05f4',
        content: '24/7 Car detailing service available! Call us anytime 🚨',
        mediaUrl: 'https://videos.pexels.com/video-files/3195394/3195394-uhd_2560_1440_25fps.mp4',
        type: StoryType.video,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now().add(const Duration(hours: 21)),
        isViewed: true,
        stats: StoryStats(views: 78, interactions: 23),
      ),
    ];
  }

  static List<SocialUser> _getMockSuggestedUsers() {
    return [
      SocialUser(
        id: 2,
        username: 'premium_auto_services',
        displayName: 'Premium Auto Services',
        profileImageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        bio: 'Luxury car care specialists in Nairobi',
        isVerified: true,
        isProvider: true,
        providerId: '9d896e1a-ed67-46b9-b33c-bcf6d519927f',
        stats: UserStats(followers: 1250, following: 50, posts: 45, likes: 2340),
        isFollowing: false,
        isFollowedBy: false,
      ),
      SocialUser(
        id: 3,
        username: 'quickfix_motors',
        displayName: 'QuickFix Motors',
        profileImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        bio: 'Fast & reliable auto repairs',
        isVerified: true,
        isProvider: true,
        providerId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        stats: UserStats(followers: 890, following: 120, posts: 67, likes: 1890),
        isFollowing: true,
        isFollowedBy: false,
      ),
    ];
  }

  static List<String> _getMockTrendingHashtags() {
    return [
      'DriveOn',
      'CarMaintenance',
      'NairobiCars',
      'AutoRepair',
      'CarWash',
      'TyreService',
    ];
  }
}
