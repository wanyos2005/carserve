# Social Media Module

This directory contains all social media related functionality for the DriveOn platform, organized in a clean modular structure.

## Directory Structure

```
social_media/
├── docs/                           # Documentation files
│   ├── REALTIME_INTEGRATION_COMPLETE.md
│   └── REALTIME_INTEGRATION_PLAN.md
├── models/                         # Data models
│   └── social_content_models.dart  # Social content data models
├── pages/                          # UI pages
│   ├── create_post_page.dart       # Post creation interface
│   └── social_hub_page.dart        # Main social hub interface
├── services/                       # Business logic services
│   ├── content_algorithm_service.dart  # TikTok-style content algorithm
│   ├── realtime_service.dart       # WebSocket real-time communication
│   └── social_service.dart         # Social media API service
├── widgets/                        # Reusable UI components
│   └── comments_section.dart       # Comments display widget
└── README.md                       # This file
```

## Features

### 🎯 Content Algorithm
- **TikTok-style recommendation system** with multi-factor scoring
- **Engagement tracking** for personalized content
- **Content diversity filtering** to prevent repetitive content
- **Real-time learning** from user interactions

### 🔄 Real-time Features
- **WebSocket connections** for live updates
- **Real-time notifications** for likes, comments, shares
- **Presence tracking** for online/offline status
- **Live engagement updates**

### 📱 Social Features
- **Post creation** with media support
- **Comments system** with nested replies
- **Like and share functionality**
- **User following system**
- **Stories support** with expiration
- **Hashtag trending** detection

### 🏢 Provider Integration
- **Sponsored content** support
- **Provider-specific content** filtering
- **Business profile** integration
- **Service promotion** tools

## Key Services

### ContentAlgorithmService
Implements intelligent content ranking based on:
- User engagement history
- Content recency
- Relevance to user interests
- Content diversity
- Provider/sponsored content boost

### SocialService
Handles all social media API interactions:
- Post creation and management
- User interactions (likes, comments, shares)
- Content discovery and search
- Media upload to Cloudflare R2

### RealtimeService
Manages real-time communication:
- WebSocket connection management
- Live message broadcasting
- Presence tracking
- Engagement analytics

## Usage

### Importing Social Media Components

```dart
// Import pages
import 'package:driveon_car_platform/social_media/pages/social_hub_page.dart';
import 'package:driveon_car_platform/social_media/pages/create_post_page.dart';

// Import services
import 'package:driveon_car_platform/social_media/services/social_service.dart';
import 'package:driveon_car_platform/social_media/services/content_algorithm_service.dart';
import 'package:driveon_car_platform/social_media/services/realtime_service.dart';

// Import models
import 'package:driveon_car_platform/social_media/models/social_content_models.dart';

// Import widgets
import 'package:driveon_car_platform/social_media/widgets/comments_section.dart';
```

### Basic Usage

```dart
// Navigate to social hub
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SocialHubPage(),
  ),
);

// Create a post
final post = await SocialService.createPost(
  content: 'Hello world!',
  hashtags: ['DriveOn', 'CarMaintenance'],
  type: PostType.text,
);

// Apply content algorithm
final rankedPosts = ContentAlgorithmService.rankPosts(
  posts,
  userId: currentUserId,
  userInterests: ['car maintenance', 'auto repair'],
);
```

## Dependencies

- `http` - API communication
- `web_socket_channel` - Real-time WebSocket connections
- `shared_preferences` - Local storage
- `image_picker` - Media selection
- `flutter/material.dart` - UI components

## Architecture

The social media module follows a clean architecture pattern:

1. **Models** - Data structures and business entities
2. **Services** - Business logic and API interactions
3. **Pages** - UI screens and user interactions
4. **Widgets** - Reusable UI components

This organization ensures:
- **Separation of concerns**
- **Easy testing and maintenance**
- **Scalable codebase**
- **Clear dependencies**

## Future Enhancements

- [ ] Video content support
- [ ] Live streaming integration
- [ ] Advanced analytics dashboard
- [ ] AI-powered content moderation
- [ ] Push notifications
- [ ] Content scheduling
- [ ] Advanced search filters
- [ ] User blocking/reporting
