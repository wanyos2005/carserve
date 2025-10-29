import 'package:flutter/material.dart';
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';
import 'package:driveon_car_platform/social_media/widgets/video_auto_player.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';

class CommunityPostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
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
              child: post.type == PostType.video
                  ? SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: VideoAutoPlayer(url: post.mediaUrls.first),
                    )
                  : Image.network(
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
                onTap: onLike,
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
                onTap: onComment,
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
                onTap: onShare,
                child: Icon(Icons.share_outlined, color: Colors.grey[600], size: 20),
              ),
            ],
          ),
        ],
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
