import 'package:flutter/material.dart';
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';
import 'package:driveon_car_platform/social_media/widgets/video_auto_player.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';

class FeaturedPostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback? onLike;

  const FeaturedPostCard({
    super.key,
    required this.post,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red[600]!,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red[600]!.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.red[600]!.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[400]!, Colors.red[400]!],
            ),
          ),
          child: Stack(
        children: [
          if (post.mediaUrls.isNotEmpty)
            post.type == PostType.video
                ? VideoAutoPlayer(url: post.mediaUrls.first)
                : Image.network(
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
                      _getUserDisplayName(post.userId),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onLike,
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
}
