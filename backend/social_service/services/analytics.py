# backend/social_service/services/analytics.py
import math
from typing import List, Dict, Optional, Tuple
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import text, func, desc
import json

class AnalyticsService:
    """Advanced analytics service for trending, recommendations, and insights"""
    
    def __init__(self):
        self.trending_weight = {
            'likes': 1.0,
            'comments': 2.0,
            'shares': 3.0,
            'views': 0.1,
            'time_decay': 0.5
        }
    
    def calculate_trending_score(self, post_data: Dict, db: Session) -> float:
        """Calculate trending score for a post using engagement and time decay"""
        try:
            # Get post engagement metrics
            likes = post_data.get('likes', 0)
            comments = post_data.get('comments', 0)
            shares = post_data.get('shares', 0)
            views = post_data.get('views', 0)
            created_at = post_data.get('created_at')
            
            # Calculate time decay (newer posts get higher scores)
            if created_at:
                hours_old = (datetime.now() - created_at).total_seconds() / 3600
                time_decay = math.exp(-self.trending_weight['time_decay'] * hours_old / 24)
            else:
                time_decay = 1.0
            
            # Calculate engagement score
            engagement_score = (
                likes * self.trending_weight['likes'] +
                comments * self.trending_weight['comments'] +
                shares * self.trending_weight['shares'] +
                views * self.trending_weight['views']
            )
            
            # Final trending score
            trending_score = engagement_score * time_decay
            
            return round(trending_score, 2)
            
        except Exception as e:
            print(f"Error calculating trending score: {str(e)}")
            return 0.0
    
    def get_trending_posts(self, limit: int = 20, db: Session = None) -> List[Dict]:
        """Get trending posts based on engagement and time"""
        try:
            # Get posts with engagement data
            query = text("""
                SELECT p.id, p.user_id, p.content, p.media_urls, p.hashtags, p.created_at,
                       COALESCE(pa.likes, 0) as likes,
                       COALESCE(pa.comments, 0) as comments,
                       COALESCE(pa.shares, 0) as shares,
                       COALESCE(pa.views, 0) as views
                FROM social.posts p
                LEFT JOIN social.post_analytics pa ON p.id = pa.post_id
                WHERE p.status = 'published'
                AND p.created_at >= NOW() - INTERVAL '7 days'
                ORDER BY p.created_at DESC
                LIMIT :limit
            """)
            
            result = db.execute(query, {"limit": limit * 3}).fetchall()
            
            # Calculate trending scores and sort
            posts_with_scores = []
            for row in result:
                post_data = {
                    'id': row[0],
                    'user_id': row[1],
                    'content': row[2],
                    'media_urls': json.loads(row[3]) if row[3] else [],
                    'hashtags': json.loads(row[4]) if row[4] else [],
                    'created_at': row[5],
                    'likes': row[6],
                    'comments': row[7],
                    'shares': row[8],
                    'views': row[9]
                }
                
                trending_score = self.calculate_trending_score(post_data, db)
                post_data['trending_score'] = trending_score
                posts_with_scores.append(post_data)
            
            # Sort by trending score and return top posts
            posts_with_scores.sort(key=lambda x: x['trending_score'], reverse=True)
            return posts_with_scores[:limit]
            
        except Exception as e:
            print(f"Error getting trending posts: {str(e)}")
            return []
    
    def get_trending_hashtags(self, limit: int = 10, db: Session = None) -> List[Dict]:
        """Get trending hashtags based on recent usage"""
        try:
            query = text("""
                SELECT h.name, h.posts_count,
                       COUNT(p.id) as recent_posts,
                       AVG(COALESCE(pa.likes, 0)) as avg_likes
                FROM social.hashtags h
                LEFT JOIN social.posts p ON JSON_EXTRACT(p.hashtags, '$') LIKE CONCAT('%', h.name, '%')
                LEFT JOIN social.post_analytics pa ON p.id = pa.post_id
                WHERE p.created_at >= NOW() - INTERVAL '24 hours'
                GROUP BY h.name, h.posts_count
                ORDER BY recent_posts DESC, avg_likes DESC
                LIMIT :limit
            """)
            
            result = db.execute(query, {"limit": limit}).fetchall()
            
            trending_hashtags = []
            for row in result:
                trending_hashtags.append({
                    'name': row[0],
                    'total_posts': row[1],
                    'recent_posts': row[2],
                    'avg_likes': float(row[3]) if row[3] else 0,
                    'trend_score': row[2] * (float(row[3]) if row[3] else 0)
                })
            
            return trending_hashtags
            
        except Exception as e:
            print(f"Error getting trending hashtags: {str(e)}")
            return []
    
    def get_personalized_feed(self, user_id: int, limit: int = 20, db: Session = None) -> List[Dict]:
        """Get personalized feed based on user interests and following"""
        try:
            # Get user's interests (from liked posts, followed users, etc.)
            user_interests = self.get_user_interests(user_id, db)
            
            # Get posts from followed users
            followed_posts = self.get_followed_users_posts(user_id, limit // 2, db)
            
            # Get posts based on interests
            interest_posts = self.get_interest_based_posts(user_interests, limit // 2, db)
            
            # Combine and deduplicate
            all_posts = followed_posts + interest_posts
            unique_posts = {post['id']: post for post in all_posts}
            
            # Sort by relevance score
            personalized_posts = list(unique_posts.values())
            personalized_posts.sort(key=lambda x: x.get('relevance_score', 0), reverse=True)
            
            return personalized_posts[:limit]
            
        except Exception as e:
            print(f"Error getting personalized feed: {str(e)}")
            return []
    
    def get_user_interests(self, user_id: int, db: Session) -> List[str]:
        """Get user's interests based on their activity"""
        try:
            # Get hashtags from user's liked posts
            query = text("""
                SELECT DISTINCT JSON_UNQUOTE(JSON_EXTRACT(p.hashtags, '$[*]')) as hashtag
                FROM social.posts p
                JOIN social.likes l ON p.id = l.post_id
                WHERE l.user_id = :user_id
                AND p.created_at >= NOW() - INTERVAL '30 days'
            """)
            
            result = db.execute(query, {"user_id": user_id}).fetchall()
            
            interests = []
            for row in result:
                if row[0] and row[0] not in interests:
                    interests.append(row[0])
            
            return interests[:10]  # Top 10 interests
            
        except Exception as e:
            print(f"Error getting user interests: {str(e)}")
            return []
    
    def get_followed_users_posts(self, user_id: int, limit: int, db: Session) -> List[Dict]:
        """Get posts from users that the user follows"""
        try:
            query = text("""
                SELECT p.id, p.user_id, p.content, p.media_urls, p.hashtags, p.created_at,
                       COALESCE(pa.likes, 0) as likes,
                       COALESCE(pa.comments, 0) as comments,
                       COALESCE(pa.shares, 0) as shares,
                       COALESCE(pa.views, 0) as views
                FROM social.posts p
                JOIN social.follows f ON p.user_id = f.following_id
                LEFT JOIN social.post_analytics pa ON p.id = pa.post_id
                WHERE f.follower_id = :user_id
                AND p.status = 'published'
                ORDER BY p.created_at DESC
                LIMIT :limit
            """)
            
            result = db.execute(query, {"user_id": user_id, "limit": limit}).fetchall()
            
            posts = []
            for row in result:
                posts.append({
                    'id': row[0],
                    'user_id': row[1],
                    'content': row[2],
                    'media_urls': json.loads(row[3]) if row[3] else [],
                    'hashtags': json.loads(row[4]) if row[4] else [],
                    'created_at': row[5],
                    'likes': row[6],
                    'comments': row[7],
                    'shares': row[8],
                    'views': row[9],
                    'relevance_score': 1.0  # High relevance for followed users
                })
            
            return posts
            
        except Exception as e:
            print(f"Error getting followed users posts: {str(e)}")
            return []
    
    def get_interest_based_posts(self, interests: List[str], limit: int, db: Session) -> List[Dict]:
        """Get posts based on user interests"""
        try:
            if not interests:
                return []
            
            # Create hashtag filter
            hashtag_filter = " OR ".join([f"JSON_CONTAINS(p.hashtags, '\"{interest}\"')" for interest in interests])
            
            query = text(f"""
                SELECT p.id, p.user_id, p.content, p.media_urls, p.hashtags, p.created_at,
                       COALESCE(pa.likes, 0) as likes,
                       COALESCE(pa.comments, 0) as comments,
                       COALESCE(pa.shares, 0) as shares,
                       COALESCE(pa.views, 0) as views
                FROM social.posts p
                LEFT JOIN social.post_analytics pa ON p.id = pa.post_id
                WHERE p.status = 'published'
                AND ({hashtag_filter})
                ORDER BY p.created_at DESC
                LIMIT :limit
            """)
            
            result = db.execute(query, {"limit": limit}).fetchall()
            
            posts = []
            for row in result:
                posts.append({
                    'id': row[0],
                    'user_id': row[1],
                    'content': row[2],
                    'media_urls': json.loads(row[3]) if row[3] else [],
                    'hashtags': json.loads(row[4]) if row[4] else [],
                    'created_at': row[5],
                    'likes': row[6],
                    'comments': row[7],
                    'shares': row[8],
                    'views': row[9],
                    'relevance_score': 0.7  # Medium relevance for interest-based
                })
            
            return posts
            
        except Exception as e:
            print(f"Error getting interest-based posts: {str(e)}")
            return []
    
    def get_user_analytics(self, user_id: int, db: Session) -> Dict:
        """Get comprehensive analytics for a user"""
        try:
            # Get user's post performance
            post_stats = db.execute(text("""
                SELECT 
                    COUNT(p.id) as total_posts,
                    AVG(COALESCE(pa.likes, 0)) as avg_likes,
                    AVG(COALESCE(pa.comments, 0)) as avg_comments,
                    AVG(COALESCE(pa.shares, 0)) as avg_shares,
                    AVG(COALESCE(pa.views, 0)) as avg_views
                FROM social.posts p
                LEFT JOIN social.post_analytics pa ON p.id = pa.post_id
                WHERE p.user_id = :user_id
                AND p.status = 'published'
            """), {"user_id": user_id}).fetchone()
            
            # Get follower growth
            follower_growth = db.execute(text("""
                SELECT COUNT(*) as new_followers
                FROM social.follows
                WHERE following_id = :user_id
                AND created_at >= NOW() - INTERVAL '30 days'
            """), {"user_id": user_id}).fetchone()
            
            # Get engagement rate
            total_engagement = db.execute(text("""
                SELECT 
                    SUM(COALESCE(pa.likes, 0)) as total_likes,
                    SUM(COALESCE(pa.comments, 0)) as total_comments,
                    SUM(COALESCE(pa.shares, 0)) as total_shares
                FROM social.posts p
                LEFT JOIN social.post_analytics pa ON p.id = pa.post_id
                WHERE p.user_id = :user_id
                AND p.status = 'published'
            """), {"user_id": user_id}).fetchone()
            
            return {
                'total_posts': post_stats[0] if post_stats[0] else 0,
                'avg_likes': float(post_stats[1]) if post_stats[1] else 0,
                'avg_comments': float(post_stats[2]) if post_stats[2] else 0,
                'avg_shares': float(post_stats[3]) if post_stats[3] else 0,
                'avg_views': float(post_stats[4]) if post_stats[4] else 0,
                'new_followers_30d': follower_growth[0] if follower_growth[0] else 0,
                'total_engagement': {
                    'likes': total_engagement[0] if total_engagement[0] else 0,
                    'comments': total_engagement[1] if total_engagement[1] else 0,
                    'shares': total_engagement[2] if total_engagement[2] else 0
                }
            }
            
        except Exception as e:
            print(f"Error getting user analytics: {str(e)}")
            return {}
    
    def get_provider_analytics(self, provider_id: str, db: Session) -> Dict:
        """Get analytics for service providers"""
        try:
            # Get provider's content performance
            content_stats = db.execute(text("""
                SELECT 
                    COUNT(p.id) as total_posts,
                    SUM(CASE WHEN p.is_sponsored THEN 1 ELSE 0 END) as sponsored_posts,
                    AVG(COALESCE(pa.likes, 0)) as avg_likes,
                    AVG(COALESCE(pa.comments, 0)) as avg_comments,
                    AVG(COALESCE(pa.shares, 0)) as avg_shares,
                    AVG(COALESCE(pa.views, 0)) as avg_views
                FROM social.posts p
                LEFT JOIN social.post_analytics pa ON p.id = pa.post_id
                WHERE p.provider_id = :provider_id
                AND p.status = 'published'
            """), {"provider_id": provider_id}).fetchone()
            
            # Get ROI metrics (if available)
            roi_metrics = db.execute(text("""
                SELECT 
                    SUM(CASE WHEN p.is_sponsored THEN COALESCE(pa.views, 0) ELSE 0 END) as sponsored_views,
                    SUM(CASE WHEN p.is_sponsored THEN COALESCE(pa.likes, 0) ELSE 0 END) as sponsored_likes
                FROM social.posts p
                LEFT JOIN social.post_analytics pa ON p.id = pa.post_id
                WHERE p.provider_id = :provider_id
                AND p.is_sponsored = true
            """), {"provider_id": provider_id}).fetchone()
            
            return {
                'total_posts': content_stats[0] if content_stats[0] else 0,
                'sponsored_posts': content_stats[1] if content_stats[1] else 0,
                'avg_likes': float(content_stats[2]) if content_stats[2] else 0,
                'avg_comments': float(content_stats[3]) if content_stats[3] else 0,
                'avg_shares': float(content_stats[4]) if content_stats[4] else 0,
                'avg_views': float(content_stats[5]) if content_stats[5] else 0,
                'sponsored_views': roi_metrics[0] if roi_metrics[0] else 0,
                'sponsored_likes': roi_metrics[1] if roi_metrics[1] else 0,
                'engagement_rate': self.calculate_engagement_rate(content_stats, db)
            }
            
        except Exception as e:
            print(f"Error getting provider analytics: {str(e)}")
            return {}
    
    def calculate_engagement_rate(self, stats: Tuple, db: Session) -> float:
        """Calculate engagement rate for content"""
        try:
            total_posts = stats[0] if stats[0] else 0
            avg_likes = float(stats[2]) if stats[2] else 0
            avg_comments = float(stats[3]) if stats[3] else 0
            avg_shares = float(stats[4]) if stats[4] else 0
            avg_views = float(stats[5]) if stats[5] else 0
            
            if avg_views == 0:
                return 0.0
            
            engagement = (avg_likes + avg_comments + avg_shares) / avg_views
            return round(engagement * 100, 2)
            
        except Exception as e:
            print(f"Error calculating engagement rate: {str(e)}")
            return 0.0

# Global analytics service instance
analytics_service = AnalyticsService()
