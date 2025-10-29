// Social Service for DriveOn Platform
// Handles all social hub interactions, content management, and user engagement

import 'dart:io';
import 'package:driveon_car_platform/services/config.dart';
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';
import 'package:driveon_car_platform/services/api_service.dart';

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
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null) queryParams['category'] = category;
      if (hashtag != null) queryParams['hashtag'] = hashtag;

      final data = await ApiService.get('/social/posts/feed', query: queryParams);
      if (data != null && data['posts'] is List) {
        return (data['posts'] as List<dynamic>)
            .map((post) => SocialPost.fromJson(post))
            .toList();
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
      final data = await ApiService.post('/social/posts', {
          'content': content,
          'media_urls': mediaUrls,
          'hashtags': hashtags,
          'type': type.name,
          'provider_id': providerId,
          'is_sponsored': isSponsored,
      });
      if (data != null) {
        // Backend returns the post directly, not wrapped in a 'post' field
        return SocialPost.fromJson(data);
      }
    } catch (e) {
      print('Error creating post: $e');
    }
    return null;
  }

  /// Like/Unlike a post
  static Future<bool> toggleLike(String postId) async {
    try {
      final data = await ApiService.post('/social/interactions/likes', {'post_id': postId});
      return data != null;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  /// Like/Unlike a comment
  static Future<bool> toggleCommentLike(String commentId) async {
    try {
      final data = await ApiService.post('/social/interactions/comment-likes', {'comment_id': commentId});
      return data != null;
    } catch (e) {
      print('Error toggling comment like: $e');
      return false;
    }
  }

  /// Share a post
  static Future<bool> sharePost(String postId) async {
    try {
      final data = await ApiService.post('/social/interactions/shares', {'post_id': postId});
      return data != null;
    } catch (e) {
      print('Error sharing post: $e');
      return false;
    }
  }

  // ==================== COMMENTS ====================

  /// Get comments for a post
  static Future<List<SocialComment>> getPostComments(String postId, {int page = 1, int limit = 20}) async {
    try {
      final data = await ApiService.get(
        "/social/interactions/comments/$postId",
        query: {"page": "$page", "limit": "$limit"},
      );
      if (data is List) {
        return data.map((c) => SocialComment.fromJson(c)).toList();
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
    return [];
  }

  /// Add a comment to a post
  static Future<SocialComment?> addComment(String postId, String content, {String? parentId}) async {
    try {
      final data = await ApiService.post(
        "/social/interactions/comments?post_id=$postId",
        {
          'content': content,
          'parent_id': parentId,
        },
      );
      if (data != null) {
        return SocialComment.fromJson(data);
      }
    } catch (e) {
      print('Error adding comment: $e');
      
      // If it's a 401 error, try once more after a brief delay
      if (e.toString().contains('401') || e.toString().contains('Token expired')) {
        print('Retrying comment after 401 error...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final retryData = await ApiService.post(
            "/social/interactions/comments?post_id=$postId",
            {
              'content': content,
              'parent_id': parentId,
            },
          );
          if (retryData != null) {
            return SocialComment.fromJson(retryData);
          }
        } catch (retryError) {
          print('Retry failed: $retryError');
        }
      }
    }
    return null;
  }

  /// Delete a comment
  static Future<bool> deleteComment(String commentId) async {
    try {
      final ok = await ApiService.delete('/social/interactions/comments/$commentId');
      return ok;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // ==================== USERS ====================

  /// Get user profile
  static Future<SocialUser?> getUserProfile(String userId) async {
    try {
      final data = await ApiService.get('/social/users/$userId');
      if (data != null) {
        return SocialUser.fromJson(data);
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

  /// Follow/Unfollow a user
  static Future<bool> toggleFollow(String userId) async {
    try {
      final data = await ApiService.post('/social/interactions/follows', {'user_id': userId});
      return data != null;
    } catch (e) {
      print('Error toggling follow: $e');
      return false;
    }
  }

  /// Get user posts
  static Future<List<SocialPost>> getUserPosts(String userId, {int page = 1, int limit = 20}) async {
    try {
      final data = await ApiService.get(
        '/social/users/$userId/posts',
        query: {'page': '$page', 'limit': '$limit'},
      );
      if (data is List) {
        return data.map((post) => SocialPost.fromJson(post)).toList();
      }
    } catch (e) {
      print('Error fetching user posts: $e');
    }
    return [];
  }

  /// Get suggested users
  static Future<List<SocialUser>> getSuggestedUsers() async {
    try {
      final resp = await ApiService.get("/social/users/suggested");
      if (resp != null) {
        final data = resp;
        if (data is Map && data['users'] is List) {
          final users = <SocialUser>[];
          for (final userData in data['users'] as List<dynamic>) {
            try {
              if (userData is Map<String, dynamic>) {
                users.add(SocialUser.fromJson(userData));
              }
            } catch (e) {
              print('Error parsing user data: $e');
              print('User data: $userData');
            }
          }
          return users;
        }
      }
    } catch (e) {
      print('Error fetching suggested users: $e');
    }
    
    // Return mock data for development
    return _getMockSuggestedUsers();
  }

  // ==================== STORIES ====================

  /// Get active stories
  static Future<List<SocialStory>> getActiveStories() async {
    try {
      final data = await ApiService.get('/social/stories/active');
      if (data is List) {
        return data.map((story) => SocialStory.fromJson(story)).toList();
      }
    } catch (e) {
      print('Error fetching stories: $e');
    }
    return [];
  }

  /// Create a story
  static Future<SocialStory?> createStory({
    required String content,
    required StoryType type,
    String? mediaUrl,
    List<String>? hashtags,
  }) async {
    try {
      final data = await ApiService.post('/social/stories', {
          'content': content,
        'type': type.toString().split('.').last,
          'media_url': mediaUrl,
        'hashtags': hashtags ?? [],
      });
      if (data != null) {
        return SocialStory.fromJson(data);
      }
    } catch (e) {
      print('Error creating story: $e');
    }
    return null;
  }

  /// View a story
  static Future<bool> viewStory(String storyId) async {
    try {
      final data = await ApiService.post('/social/stories/$storyId/view', {});
      return data != null;
    } catch (e) {
      print('Error viewing story: $e');
      return false;
    }
  }

  // ==================== HASHTAGS ====================

  /// Get trending hashtags
  static Future<List<String>> getTrendingHashtags() async {
    try {
      final data = await ApiService.get('/social/hashtags/trending');
      if (data is List) {
        return data.cast<String>();
      }
    } catch (e) {
      print('Error fetching trending hashtags: $e');
    }
    return [];
  }

  // ==================== MEDIA UPLOAD ====================

  /// Upload media file
  static Future<String?> uploadMedia(File file, {String? type, String? folder}) async {
    try {
      final data = await ApiService.uploadMultipart(
        '/social/media/upload',
        fields: {
          if (type != null) 'type': type,
          if (folder != null) 'folder': folder,
        },
        files: {'file': file},
      );
      if (data != null && data['url'] != null) {
        return data['url'];
      }
    } catch (e) {
      print('Error uploading media: $e');
    }
    return null;
  }

  // ==================== AUTHENTICATION ====================
  // Note: Authentication is now handled by ApiService

  // ==================== MOCK DATA ====================

  /// Get mock feed posts for development
  static List<SocialPost> _getMockFeedPosts() {
    return [
      SocialPost(
        id: '1',
        userId: 1,
        content: 'Just got my car serviced! Great experience at AutoCare Kenya. #CarMaintenance #NairobiCars',
        mediaUrls: ['https://picsum.photos/400/400?random=1'],
        hashtags: ['CarMaintenance', 'NairobiCars'],
        type: PostType.image,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        stats: PostStats(
          likes: 15,
          comments: 3,
          shares: 1,
          views: 120,
          isLikedByUser: false,
          isSharedByUser: false,
        ),
        isSponsored: false,
        status: PostStatus.published,
      ),
      SocialPost(
        id: '2',
        userId: 2,
        content: 'Electric vehicles are the future! Spotted a Tesla in Westlands today. #ElectricVehicles #SustainableMobility',
        mediaUrls: ['https://picsum.photos/400/400?random=2'],
        hashtags: ['ElectricVehicles', 'SustainableMobility'],
        type: PostType.image,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        stats: PostStats(
          likes: 28,
          comments: 7,
          shares: 3,
          views: 200,
          isLikedByUser: true,
          isSharedByUser: false,
        ),
        isSponsored: false,
        status: PostStatus.published,
      ),
      SocialPost(
        id: '3',
        userId: 3,
        content: 'Biked to work today instead of driving. Feeling great and helping the environment! 🌱 #CarFreeLife #EcoFriendly',
        mediaUrls: [],
        hashtags: ['CarFreeLife', 'EcoFriendly'],
        type: PostType.text,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        stats: PostStats(
          likes: 42,
          comments: 12,
          shares: 8,
          views: 350,
          isLikedByUser: false,
          isSharedByUser: true,
        ),
        isSponsored: false,
        status: PostStatus.published,
      ),
    ];
  }

  /// Get mock suggested users for development
  static List<SocialUser> _getMockSuggestedUsers() {
    return [
      SocialUser(
        id: 1,
        username: 'AutoExpert_KE',
        displayName: 'Auto Expert Kenya',
        profileImageUrl: 'https://picsum.photos/100/100?random=1',
        bio: 'Professional auto mechanic with 15+ years experience',
        isVerified: true,
        isProvider: true,
        providerId: '1',
        stats: UserStats(
          followers: 1250,
          following: 300,
          posts: 45,
          likes: 3200,
        ),
        isFollowing: false,
        isFollowedBy: false,
      ),
      SocialUser(
        id: 2,
        username: 'EcoWarrior_KE',
        displayName: 'Eco Warrior Kenya',
        profileImageUrl: 'https://picsum.photos/100/100?random=2',
        bio: 'Sustainability advocate and electric vehicle enthusiast',
        isVerified: false,
        isProvider: false,
        stats: UserStats(
          followers: 890,
          following: 450,
          posts: 23,
          likes: 1800,
        ),
        isFollowing: false,
        isFollowedBy: false,
      ),
      SocialUser(
        id: 3,
        username: 'CarGuru_Nairobi',
        displayName: 'Car Guru Nairobi',
        profileImageUrl: 'https://picsum.photos/100/100?random=3',
        bio: 'Car enthusiast sharing tips and tricks for car maintenance',
        isVerified: true,
        isProvider: false,
        stats: UserStats(
          followers: 2100,
          following: 600,
          posts: 67,
          likes: 5400,
        ),
        isFollowing: true,
        isFollowedBy: false,
      ),
    ];
  }
}