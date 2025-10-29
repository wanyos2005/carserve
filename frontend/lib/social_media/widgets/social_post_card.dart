import 'package:flutter/material.dart';
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';
import 'package:driveon_car_platform/social_media/widgets/video_auto_player.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';

class SocialPostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const SocialPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
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
                                _getUserDisplayName(post.userId),
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
            
            // Media content (image or video)
            if (post.mediaUrls.isNotEmpty)
              AspectRatio(
                aspectRatio: 1.0,
                child: post.type == PostType.video
                    ? VideoAutoPlayer(url: post.mediaUrls.first)
                    : Image.network(
                        post.mediaUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
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
                    onTap: onLike,
                    child: Icon(
                      post.stats.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                      color: post.stats.isLikedByUser ? Colors.red : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onComment,
                    child: Icon(Icons.comment_outlined, color: Colors.grey[600], size: 24),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onShare,
                    child: Icon(Icons.send_outlined, color: Colors.grey[600], size: 24),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onBookmark,
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
                      text: '${_getUserDisplayName(post.userId)} ',
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
                  onTap: onComment,
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
      ),
    );
  }

  /// Get user display name for posts
  String _getUserDisplayName(int userId) {
    try {
      final context = UserContextService.currentContext;
      
      // If this is the current user's post, use their display name
      if (context?.id != null && int.tryParse(context!.id!) == userId) {
        return UserContextService.getDisplayName();
      }
      
      // For other users, try to get from context or use fallback
      if (context?.rawData != null) {
        final userData = context!.rawData!;
        if (userData['id']?.toString() == userId.toString()) {
          return userData['name'] ?? userData['provider_name'] ?? 'User $userId';
        }
      }
      
      // Fallback to generic user name
      return 'User $userId';
    } catch (e) {
      return 'User $userId';
    }
  }

  /// Format time ago
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
}
