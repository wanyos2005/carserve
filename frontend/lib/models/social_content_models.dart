// Social Content Models for DriveOn Platform
// Models for social hub content, interactions, and user engagement

class SocialPost {
  final String id;
  final int userId;  // Changed from String to int to match backend
  final String? providerId;
  final String content;
  final List<String> mediaUrls;
  final List<String> hashtags;
  final PostType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostStats stats;
  final bool isSponsored;
  final String? sponsoredBy;
  final PostStatus status;

  SocialPost({
    required this.id,
    required this.userId,
    this.providerId,
    required this.content,
    this.mediaUrls = const [],
    this.hashtags = const [],
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.stats,
    this.isSponsored = false,
    this.sponsoredBy,
    this.status = PostStatus.published,
  });

  // Helper getters
  bool get isProvider => providerId != null && providerId!.isNotEmpty;

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'],
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      providerId: json['provider_id'],
      content: json['content'],
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      type: PostType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PostType.text,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      stats: PostStats.fromJson(json['stats'] ?? {}),
      isSponsored: json['is_sponsored'] ?? false,
      sponsoredBy: json['sponsored_by'],
      status: PostStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PostStatus.published,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider_id': providerId,
      'content': content,
      'media_urls': mediaUrls,
      'hashtags': hashtags,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'stats': stats.toJson(),
      'is_sponsored': isSponsored,
      'sponsored_by': sponsoredBy,
      'status': status.name,
    };
  }
}

class PostStats {
  final int likes;
  final int comments;
  final int shares;
  final int views;
  final bool isLikedByUser;
  final bool isSharedByUser;

  PostStats({
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.views = 0,
    this.isLikedByUser = false,
    this.isSharedByUser = false,
  });

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      views: json['views'] ?? 0,
      isLikedByUser: json['is_liked_by_user'] ?? false,
      isSharedByUser: json['is_shared_by_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'views': views,
      'is_liked_by_user': isLikedByUser,
      'is_shared_by_user': isSharedByUser,
    };
  }
}

class SocialComment {
  final String id;
  final String postId;
  final int userId;  // Changed from String to int
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final bool isLikedByUser;
  final List<SocialComment> replies;

  SocialComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
    this.isLikedByUser = false,
    this.replies = const [],
  });

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      likes: json['likes'] ?? 0,
      isLikedByUser: json['is_liked_by_user'] ?? false,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => SocialComment.fromJson(reply))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'likes': likes,
      'is_liked_by_user': isLikedByUser,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }
}

class SocialUser {
  final int id;  // Changed from String to int to match backend
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final bool isVerified;
  final bool isProvider;
  final String? providerId;
  final UserStats stats;
  final bool isFollowing;
  final bool isFollowedBy;

  SocialUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
    this.isVerified = false,
    this.isProvider = false,
    this.providerId,
    required this.stats,
    this.isFollowing = false,
    this.isFollowedBy = false,
  });

  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'],
      displayName: json['display_name'],
      profileImageUrl: json['profile_image_url'],
      bio: json['bio'],
      isVerified: json['is_verified'] ?? false,
      isProvider: json['is_provider'] ?? false,
      providerId: json['provider_id'],
      stats: UserStats.fromJson(json['stats'] ?? {}),
      isFollowing: json['is_following'] ?? false,
      isFollowedBy: json['is_followed_by'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'profile_image_url': profileImageUrl,
      'bio': bio,
      'is_verified': isVerified,
      'is_provider': isProvider,
      'provider_id': providerId,
      'stats': stats.toJson(),
      'is_following': isFollowing,
      'is_followed_by': isFollowedBy,
    };
  }
}

class UserStats {
  final int followers;
  final int following;
  final int posts;
  final int likes;

  UserStats({
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.likes = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      posts: json['posts'] ?? 0,
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers': followers,
      'following': following,
      'posts': posts,
      'likes': likes,
    };
  }
}

class SocialStory {
  final String id;
  final int userId;  // Changed from String to int
  final String? providerId;
  final String content;
  final String? mediaUrl;
  final StoryType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isViewed;
  final StoryStats stats;

  SocialStory({
    required this.id,
    required this.userId,
    this.providerId,
    required this.content,
    this.mediaUrl,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
    required this.stats,
  });

  factory SocialStory.fromJson(Map<String, dynamic> json) {
    return SocialStory(
      id: json['id'],
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      providerId: json['provider_id'],
      content: json['content'],
      mediaUrl: json['media_url'],
      type: StoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StoryType.image,
      ),
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      isViewed: json['is_viewed'] ?? false,
      stats: StoryStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider_id': providerId,
      'content': content,
      'media_url': mediaUrl,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_viewed': isViewed,
      'stats': stats.toJson(),
    };
  }
}

class StoryStats {
  final int views;
  final int interactions;

  StoryStats({
    this.views = 0,
    this.interactions = 0,
  });

  factory StoryStats.fromJson(Map<String, dynamic> json) {
    return StoryStats(
      views: json['views'] ?? 0,
      interactions: json['interactions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'views': views,
      'interactions': interactions,
    };
  }
}

// Enums
enum PostType {
  text,
  image,
  video,
  carousel,
  poll,
  story,
}

enum PostStatus {
  draft,
  published,
  archived,
  deleted,
}

enum StoryType {
  image,
  video,
  text,
}

// Content Categories for better organization
enum ContentCategory {
  maintenance,
  reviews,
  sustainability,
  lifestyle,
  provider,
  community,
  education,
  promotion,
}

// Interaction Types
enum InteractionType {
  like,
  comment,
  share,
  save,
  follow,
  view,
}
