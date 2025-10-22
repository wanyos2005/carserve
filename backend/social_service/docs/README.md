# Social Service - DriveOn Platform

The Social Service is a comprehensive microservice that powers the social hub functionality of the DriveOn platform. It provides Instagram/Twitter/Pinterest-like features for car owners, service providers, and the broader automotive community.

## Features

### Core Social Features
- **Posts**: Create, read, update, delete social posts with media support
- **Stories**: 24-hour expiring stories with view tracking
- **Comments**: Nested comment system with replies
- **Likes & Shares**: Social interactions and engagement tracking
- **Follow System**: User following and follower management
- **Hashtags**: Content discovery through hashtag system

### Provider Integration
- **Sponsored Content**: Provider-sponsored posts and stories
- **Provider Profiles**: Enhanced profiles for service providers
- **Analytics**: Detailed analytics for providers and content creators
- **Verification**: Provider verification badges and status

### Content Discovery
- **Search**: Global search across posts, users, and hashtags
- **Trending**: Trending posts, hashtags, and users
- **Feed**: Personalized feed based on following and interests
- **Explore**: Content discovery for non-followers

### Analytics & Insights
- **Post Analytics**: Views, likes, comments, shares, engagement rates
- **User Analytics**: Follower growth, engagement metrics
- **Provider Analytics**: ROI tracking, conversion rates
- **Trending Analytics**: Real-time trending content analysis

## Architecture

### Database Schema
The service uses PostgreSQL with a dedicated `social` schema containing:

- **posts**: Social posts with media and hashtag support
- **stories**: 24-hour expiring stories
- **comments**: Nested comment system
- **likes**: Like relationships for posts and comments
- **shares**: Share tracking and analytics
- **follows**: User following relationships
- **story_views**: Story view tracking
- **post_analytics**: Post engagement metrics
- **user_profiles**: Enhanced user profiles
- **hashtags**: Hashtag usage tracking
- **notifications**: Social notifications

### API Endpoints

#### Posts
- `POST /social/posts/` - Create a new post
- `GET /social/posts/feed` - Get personalized feed
- `GET /social/posts/{post_id}` - Get specific post
- `PUT /social/posts/{post_id}` - Update post
- `DELETE /social/posts/{post_id}` - Delete post
- `POST /social/posts/{post_id}/like` - Like/unlike post
- `POST /social/posts/{post_id}/share` - Share post
- `GET /social/posts/trending` - Get trending posts
- `GET /social/posts/hashtag/{hashtag}` - Get posts by hashtag
- `GET /social/posts/provider/{provider_id}` - Get provider posts

#### Stories
- `POST /social/stories/` - Create a new story
- `GET /social/stories/` - Get active stories
- `GET /social/stories/{story_id}` - Get specific story
- `POST /social/stories/{story_id}/view` - Mark story as viewed
- `DELETE /social/stories/{story_id}` - Delete story

#### Interactions
- `POST /social/interactions/comments` - Create comment
- `GET /social/interactions/comments/{post_id}` - Get post comments
- `PUT /social/interactions/comments/{comment_id}` - Update comment
- `DELETE /social/interactions/comments/{comment_id}` - Delete comment
- `POST /social/interactions/likes` - Like/unlike content
- `POST /social/interactions/shares` - Share content
- `POST /social/interactions/follows` - Follow/unfollow user
- `GET /social/interactions/follows/{user_id}/followers` - Get followers
- `GET /social/interactions/follows/{user_id}/following` - Get following

#### Users
- `POST /social/users/profile` - Create user profile
- `GET /social/users/profile/me` - Get my profile
- `GET /social/users/profile/{user_id}` - Get user profile
- `PUT /social/users/profile` - Update profile
- `GET /social/users/search` - Search users
- `GET /social/users/suggested` - Get suggested users

#### Search & Discovery
- `GET /social/search/posts` - Search posts
- `GET /social/search/users` - Search users
- `GET /social/search/hashtags` - Search hashtags
- `GET /social/search/trending/hashtags` - Get trending hashtags
- `GET /social/search/trending/users` - Get trending users
- `GET /social/search/global` - Global search

#### Analytics
- `GET /social/analytics/posts/{post_id}` - Get post analytics
- `GET /social/analytics/user/me` - Get user analytics
- `GET /social/analytics/provider/{provider_id}` - Get provider analytics
- `GET /social/analytics/trending/posts` - Get trending posts analytics
- `GET /social/analytics/trending/hashtags` - Get trending hashtags analytics
- `GET /social/analytics/engagement/overview` - Get engagement overview

## Configuration

### Environment Variables
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `SECRET_KEY`: JWT secret key
- `ALLOWED_ORIGINS`: CORS allowed origins
- `ENABLE_CONTENT_MODERATION`: Enable content moderation
- `ENABLE_ANALYTICS`: Enable analytics tracking
- `ENABLE_NOTIFICATIONS`: Enable push notifications
- `RATE_LIMIT_ENABLED`: Enable rate limiting
- `MEDIA_STORAGE_TYPE`: Media storage type (local, s3, cloudflare)
- `MAX_FILE_SIZE`: Maximum file upload size

### Docker Configuration
The service runs on port 8008 and is configured in `docker-compose.yml`:

```yaml
social-service:
  build:
    context: ./backend/social_service
    dockerfile: Dockerfile
  ports:
    - "8008:8008"
  environment:
    - DATABASE_URL=postgresql+psycopg2://AdminDb:Ngojakwanza@postgres:5432/car_platform
    - REDIS_URL=redis://redis:6379
    - SECRET_KEY=supersecret
    - ALLOWED_ORIGINS=*
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
```

## Development

### Setup
1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Set up database migrations:
   ```bash
   alembic upgrade head
   ```

3. Run the service:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8008 --reload
   ```

### Database Migrations
The service uses Alembic for database migrations:

```bash
# Create a new migration
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Rollback migrations
alembic downgrade -1
```

### Testing
```bash
# Run tests (when implemented)
pytest tests/

# Run with coverage
pytest --cov=. tests/
```

## Integration

### Frontend Integration
The social service integrates with the Flutter frontend through:
- REST API endpoints for all social functionality
- Real-time notifications via WebSocket (future)
- Media upload endpoints for images and videos
- Analytics dashboard for providers

### Provider Integration
Service providers can:
- Create sponsored content and stories
- Track engagement and ROI
- Access detailed analytics
- Manage their social presence

### Cross-Service Integration
- **User Service**: User authentication and profile data
- **Service Provider Service**: Provider information and verification
- **Alert Service**: Social notifications and alerts
- **Analytics Service**: Cross-platform analytics (future)

## Security

### Authentication
- JWT-based authentication
- Role-based access control
- Provider verification system

### Content Moderation
- Automated content filtering
- User reporting system
- Admin moderation tools

### Rate Limiting
- API rate limiting per user
- Content creation limits
- Spam prevention

## Performance

### Caching
- Redis caching for frequently accessed data
- Post analytics caching
- User profile caching

### Database Optimization
- Indexed queries for performance
- Connection pooling
- Query optimization

### Scalability
- Horizontal scaling support
- Load balancing ready
- Microservice architecture

## Monitoring

### Health Checks
- Service health endpoint: `/health`
- Database connectivity checks
- Redis connectivity checks

### Metrics
- Request/response metrics
- Database performance metrics
- Cache hit/miss ratios

### Logging
- Structured logging
- Request/response logging
- Error tracking

## Future Enhancements

### Planned Features
- Real-time messaging
- Live streaming integration
- Advanced recommendation engine
- AI-powered content moderation
- Video content support
- Stories with interactive elements
- Social commerce integration
- Advanced analytics dashboard

### Technical Improvements
- GraphQL API support
- WebSocket real-time updates
- Advanced caching strategies
- Machine learning integration
- Performance optimizations
- Enhanced security features