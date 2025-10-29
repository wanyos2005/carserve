import 'package:flutter/material.dart';
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';
import 'package:driveon_car_platform/social_media/widgets/suggested_user_card.dart';

class SuggestedUsersSection extends StatelessWidget {
  final List<SocialUser> users;
  final void Function(SocialUser user) onTap;

  const SuggestedUsersSection({super.key, required this.users, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Suggested for you",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SuggestedUserCard(
                    user: user,
                    onTap: () => onTap(user),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


