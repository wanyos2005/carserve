import 'package:flutter/material.dart';
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';

class SuggestedUserCard extends StatelessWidget {
  final SocialUser user;
  final VoidCallback? onTap;

  const SuggestedUserCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
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
}


