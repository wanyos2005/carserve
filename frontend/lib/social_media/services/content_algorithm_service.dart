// Content Algorithm Service for DriveOn Platform
// Implements TikTok-style content recommendation algorithm

import 'package:driveon_car_platform/social_media/models/social_content_models.dart';

class ContentAlgorithmService {
  // Algorithm weights for different factors
  static const double _engagementWeight = 0.4;
  static const double _recencyWeight = 0.2;
  static const double _relevanceWeight = 0.2;
  static const double _providerWeight = 0.1;

  /// Apply TikTok-style algorithm to rank posts
  static List<SocialPost> rankPosts(List<SocialPost> posts, {
    int? userId,
    List<String>? userInterests,
    List<String>? userHashtags,
    Map<String, double>? userEngagementHistory,
  }) {
    if (posts.isEmpty) return posts;

    // Calculate scores for each post
    final scoredPosts = posts.map((post) {
      final score = _calculatePostScore(
        post,
        userId: userId,
        userInterests: userInterests,
        userHashtags: userHashtags,
        userEngagementHistory: userEngagementHistory,
      );
      return _ScoredPost(post: post, score: score);
    }).toList();

    // Sort by score (highest first)
    scoredPosts.sort((a, b) => b.score.compareTo(a.score));

    // Apply diversity filter to avoid too many similar posts
    final diversifiedPosts = _applyDiversityFilter(scoredPosts);

    return diversifiedPosts.map((scoredPost) => scoredPost.post).toList();
  }

  /// Calculate engagement score for a post
  static double _calculateEngagementScore(SocialPost post) {
    final stats = post.stats;
    final totalEngagement = stats.likes + stats.comments + stats.shares + stats.views;
    
    if (totalEngagement == 0) return 0.0;
    
    // Normalize engagement based on post age
    final ageInHours = DateTime.now().difference(post.createdAt).inHours;
    final ageFactor = ageInHours < 1 ? 1.0 : 1.0 / (1 + ageInHours * 0.1);
    
    return (totalEngagement * ageFactor) / 100.0; // Normalize to 0-1 range
  }

  /// Calculate recency score for a post
  static double _calculateRecencyScore(SocialPost post) {
    final ageInHours = DateTime.now().difference(post.createdAt).inHours;
    
    // Exponential decay: newer posts get higher scores
    if (ageInHours < 1) return 1.0;
    if (ageInHours < 24) return 0.8;
    if (ageInHours < 168) return 0.6; // 1 week
    if (ageInHours < 720) return 0.4; // 1 month
    return 0.2;
  }

  /// Calculate relevance score based on user interests
  static double _calculateRelevanceScore(
    SocialPost post, {
    List<String>? userInterests,
    List<String>? userHashtags,
  }) {
    if (userInterests == null && userHashtags == null) return 0.5;

    double score = 0.0;
    int matches = 0;

    // Check hashtag matches
    if (userHashtags != null) {
      for (final hashtag in post.hashtags) {
        if (userHashtags.contains(hashtag.toLowerCase())) {
          matches++;
          score += 0.3;
        }
      }
    }

    // Check content relevance (simple keyword matching)
    if (userInterests != null) {
      final contentLower = post.content.toLowerCase();
      for (final interest in userInterests) {
        if (contentLower.contains(interest.toLowerCase())) {
          matches++;
          score += 0.2;
        }
      }
    }

    // Normalize score
    return matches > 0 ? (score / matches).clamp(0.0, 1.0) : 0.5;
  }

  /// Calculate diversity score to avoid similar content
  static double _calculateDiversityScore(
    SocialPost post,
    List<SocialPost> recentPosts,
  ) {
    if (recentPosts.isEmpty) return 1.0;

    double similarity = 0.0;
    for (final recentPost in recentPosts.take(5)) { // Check last 5 posts
      if (recentPost.userId == post.userId) {
        similarity += 0.3; // Same user
      }
      
      // Check hashtag similarity
      final commonHashtags = post.hashtags
          .where((tag) => recentPost.hashtags.contains(tag))
          .length;
      similarity += (commonHashtags / post.hashtags.length) * 0.4;
      
      // Check content similarity (simple)
      final contentSimilarity = _calculateContentSimilarity(
        post.content,
        recentPost.content,
      );
      similarity += contentSimilarity * 0.3;
    }

    return (1.0 - similarity).clamp(0.0, 1.0);
  }

  /// Calculate provider boost score
  static double _calculateProviderScore(SocialPost post) {
    if (!post.isProvider) return 0.5;
    
    // Sponsored content gets a boost
    if (post.isSponsored) return 0.8;
    
    // Regular provider content gets slight boost
    return 0.6;
  }

  /// Calculate overall post score
  static double _calculatePostScore(
    SocialPost post, {
    int? userId,
    List<String>? userInterests,
    List<String>? userHashtags,
    Map<String, double>? userEngagementHistory,
  }) {
    final engagementScore = _calculateEngagementScore(post);
    final recencyScore = _calculateRecencyScore(post);
    final relevanceScore = _calculateRelevanceScore(
      post,
      userInterests: userInterests,
      userHashtags: userHashtags,
    );
    final providerScore = _calculateProviderScore(post);

    // Calculate weighted score
    double score = (engagementScore * _engagementWeight) +
                  (recencyScore * _recencyWeight) +
                  (relevanceScore * _relevanceWeight) +
                  (providerScore * _providerWeight);

    // Apply user-specific adjustments
    if (userId != null && userEngagementHistory != null) {
      final userEngagement = userEngagementHistory[post.id] ?? 0.0;
      score += userEngagement * 0.1; // Boost posts user has engaged with
    }

    return score.clamp(0.0, 1.0);
  }

  /// Apply diversity filter to avoid similar content
  static List<_ScoredPost> _applyDiversityFilter(List<_ScoredPost> scoredPosts) {
    final filteredPosts = <_ScoredPost>[];
    final recentPosts = <SocialPost>[];

    for (final scoredPost in scoredPosts) {
      final diversityScore = _calculateDiversityScore(
        scoredPost.post,
        recentPosts,
      );

      // Adjust score based on diversity
      final adjustedScore = scoredPost.score * (0.7 + diversityScore * 0.3);
      
      filteredPosts.add(_ScoredPost(
        post: scoredPost.post,
        score: adjustedScore,
      ));

      recentPosts.add(scoredPost.post);
      
      // Keep only last 10 posts for diversity calculation
      if (recentPosts.length > 10) {
        recentPosts.removeAt(0);
      }
    }

    // Re-sort by adjusted scores
    filteredPosts.sort((a, b) => b.score.compareTo(a.score));
    
    return filteredPosts;
  }

  /// Calculate content similarity between two posts
  static double _calculateContentSimilarity(String content1, String content2) {
    final words1 = content1.toLowerCase().split(' ');
    final words2 = content2.toLowerCase().split(' ');
    
    if (words1.isEmpty || words2.isEmpty) return 0.0;
    
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;
    
    return commonWords / totalWords;
  }

  /// Get trending hashtags based on recent activity
  static List<String> getTrendingHashtags(List<SocialPost> posts) {
    final hashtagCounts = <String, int>{};
    final now = DateTime.now();
    
    // Count hashtags from posts in the last 7 days
    for (final post in posts) {
      final ageInDays = now.difference(post.createdAt).inDays;
      if (ageInDays <= 7) {
        for (final hashtag in post.hashtags) {
          hashtagCounts[hashtag] = (hashtagCounts[hashtag] ?? 0) + 1;
        }
      }
    }
    
    // Sort by count and return top hashtags
    final sortedHashtags = hashtagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHashtags.take(10).map((entry) => entry.key).toList();
  }

  /// Get content categories based on hashtags and content
  static List<ContentCategory> getContentCategories(SocialPost post) {
    final categories = <ContentCategory>[];
    final content = post.content.toLowerCase();
    
    // Maintenance-related
    if (content.contains('repair') || content.contains('maintenance') ||
        post.hashtags.any((tag) => ['repair', 'maintenance', 'service'].contains(tag.toLowerCase()))) {
      categories.add(ContentCategory.maintenance);
    }
    
    // Reviews
    if (content.contains('review') || content.contains('rating') ||
        post.hashtags.any((tag) => ['review', 'rating'].contains(tag.toLowerCase()))) {
      categories.add(ContentCategory.reviews);
    }
    
    // Sustainability
    if (content.contains('eco') || content.contains('green') || content.contains('sustainable') ||
        post.hashtags.any((tag) => ['eco', 'green', 'sustainable'].contains(tag.toLowerCase()))) {
      categories.add(ContentCategory.sustainability);
    }
    
    // Provider content
    if (post.isProvider) {
      categories.add(ContentCategory.provider);
    }
    
    // Default to community if no specific category
    if (categories.isEmpty) {
      categories.add(ContentCategory.community);
    }
    
    return categories;
  }

  /// Generate personalized feed based on user behavior
  static List<SocialPost> generatePersonalizedFeed(
    List<SocialPost> allPosts, {
    required int userId,
    List<String>? userInterests,
    List<String>? userHashtags,
    Map<String, double>? userEngagementHistory,
    int limit = 20,
  }) {
    // Rank all posts
    final rankedPosts = rankPosts(
      allPosts,
      userId: userId,
      userInterests: userInterests,
      userHashtags: userHashtags,
      userEngagementHistory: userEngagementHistory,
    );
    
    // Return top posts up to limit
    return rankedPosts.take(limit).toList();
  }

  /// Track user engagement for algorithm learning
  static void trackEngagement({
    required String postId,
    required InteractionType interactionType,
    required int userId,
  }) {
    // This would typically save to a database or analytics service
    // For now, we'll just log it
    print('User $userId $interactionType on post $postId');
  }
}

/// Helper class for scored posts
class _ScoredPost {
  final SocialPost post;
  final double score;

  _ScoredPost({required this.post, required this.score});
}

/// Public class for scored posts
class ScoredPost {
  final SocialPost post;
  final double score;

  ScoredPost({required this.post, required this.score});
}
