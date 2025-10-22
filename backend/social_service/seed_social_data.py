#!/usr/bin/env python3
"""
Comprehensive social service seeding script for DriveOn platform.
This script populates all social service tables with realistic data including:
- User profiles
- Social posts (text, image, video, sponsored)
- Stories
- Comments, likes, shares
- Follows
- Hashtags
- Notifications
- Analytics

Usage:
    python seed_social_data.py
"""

import psycopg2
import os
import uuid
import json
import random
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_connection():
    """Get database connection using the exact DATABASE_URL"""
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        # Normalize SQLAlchemy-style URL to psycopg2-compatible
        if database_url.startswith("postgresql+psycopg2://"):
            database_url = database_url.replace("postgresql+psycopg2://", "postgresql://", 1)
        return psycopg2.connect(database_url)
    else:
        return psycopg2.connect(
            host=os.getenv('DB_HOST', 'postgres'),
            port=os.getenv('DB_PORT', '5432'),
            database=os.getenv('DB_NAME', 'car_platform'),
            user=os.getenv('DB_USER', 'AdminDb'),
            password=os.getenv('DB_PASSWORD', 'Ngojakwanza')
        )

def create_social_schema(conn):
    """Create the social schema if it doesn't exist"""
    cursor = conn.cursor()
    try:
        cursor.execute("CREATE SCHEMA IF NOT EXISTS social")
        conn.commit()
        print("✅ Social schema created/verified")
    except Exception as e:
        print(f"⚠️  Schema creation: {str(e)}")
    finally:
        cursor.close()

def get_providers_data():
    """Get the 5 selected providers with their services"""
    return [
        {
            "provider_id": "864b62a2-1b85-45de-8a5c-4d3e0f9ac058",
            "provider_name": "Premium Auto Services - Karen",
            "description": "Luxury car specialists with state-of-the-art equipment. Authorized service center for premium brands.",
            "contact_info": {
                "phone": "+254 20 123 4567",
                "email": "premium@autoservices.co.ke",
                "website": "www.premiumautoservices.co.ke"
            },
            "location": {
                "area": "Mombasa Road",
                "coordinates": {"lat": -1.3167, "lng": 36.8833},
                "address": "Mombasa Road, Kenya"
            },
            "rating": 4.8,
            "is_registered": True,
            "category": {"id": 2, "name": "Garage / Mechanic"},
            "services": [
                {"service_name": "Ceramic Coating / Waxing", "price": "KSh 25,000 - 50,000"},
                {"service_name": "Engine Overhaul / Rebuild", "price": "KSh 150,000 - 500,000"},
                {"service_name": "Full Body Paint", "price": "KSh 80,000 - 200,000"},
                {"service_name": "Engine Oil Change", "price": "KSh 8,000 - 18,000"}
            ]
        },
        {
            "provider_id": "bf851ac3-9745-4416-a110-771dd51d84cd",
            "provider_name": "QuickFix Motors - Industrial Area",
            "description": "Fast and reliable car repair services. Open 7 days a week with emergency services available.",
            "contact_info": {
                "phone": "+254 722 987 654",
                "email": "quickfix@motors.co.ke",
                "whatsapp": "+254 722 987 654"
            },
            "location": {
                "area": "Runda",
                "coordinates": {"lat": -1.2, "lng": 36.8},
                "address": "Runda, Kenya"
            },
            "rating": 4.2,
            "is_registered": True,
            "category": {"id": 2, "name": "Garage / Mechanic"},
            "services": [
                {"service_name": "Jump Start", "price": "KSh 1,500"},
                {"service_name": "Battery Testing & Replacement", "price": "KSh 15,000 - 35,000"},
                {"service_name": "Tyre Replacement", "price": "KSh 8,000 - 25,000"},
                {"service_name": "Engine Oil Change", "price": "KSh 2,800 - 6,500"}
            ]
        },
        {
            "provider_id": "9d896e1a-ed67-46b9-b33c-bcf6d519927f",
            "provider_name": "AutoCare Kenya - Westlands",
            "description": "Full-service automotive repair center specializing in European and Japanese vehicles. 15+ years experience with certified technicians.",
            "contact_info": {
                "phone": "+254 700 123 456",
                "email": "info@autocarekenya.co.ke",
                "website": "www.autocarekenya.co.ke"
            },
            "location": {
                "area": "Kasarani",
                "coordinates": {"lat": -1.2167, "lng": 36.9},
                "address": "Kasarani, Kenya"
            },
            "rating": 4.5,
            "is_registered": True,
            "category": {"id": 2, "name": "Garage / Mechanic"},
            "services": [
                {"service_name": "General Vehicle Inspection", "price": "KSh 2,500 - 4,000"},
                {"service_name": "AC Gas Refill", "price": "KSh 4,500 - 7,000"},
                {"service_name": "Engine Tune-Up", "price": "KSh 12,000 - 25,000"},
                {"service_name": "Brake Pad Replacement", "price": "KSh 8,000 - 15,000"}
            ]
        },
        {
            "provider_id": "66fd2721-f5ec-421a-82db-147621ff05f4",
            "provider_name": "Sparkle Auto Spa - Kilimani",
            "description": "Premium car wash and detailing services with eco-friendly products and professional equipment.",
            "contact_info": {
                "phone": "+254 700 777 888",
                "email": "info@sparkleautospa.co.ke",
                "instagram": "@sparkleautospa"
            },
            "location": {
                "area": "Kilimani",
                "coordinates": {"lat": -1.3, "lng": 36.7833},
                "address": "Kilimani, Kenya"
            },
            "rating": 4.6,
            "is_registered": True,
            "category": {"id": 4, "name": "Car Wash & Detailing"},
            "services": [
                {"service_name": "Ceramic Coating / Waxing", "price": "KSh 15,000 - 35,000"},
                {"service_name": "Engine Bay Cleaning", "price": "KSh 1,500 - 3,000"},
                {"service_name": "Interior Deep Clean", "price": "KSh 2,500 - 5,000"},
                {"service_name": "Exterior Wash", "price": "KSh 800 - 2,000"}
            ]
        },
        {
            "provider_id": "9e5e7b0a-273f-4d34-8914-2c174e720a65",
            "provider_name": "TyreMax Kenya - Eastleigh",
            "description": "Leading tyre dealer with all major brands. Wheel alignment, balancing, and puncture repair services.",
            "contact_info": {
                "phone": "+254 700 444 555",
                "email": "sales@tyremaxkenya.co.ke",
                "website": "www.tyremaxkenya.co.ke"
            },
            "location": {
                "area": "Thika Road",
                "coordinates": {"lat": -1.2, "lng": 36.85},
                "address": "Thika Road, Kenya"
            },
            "rating": 4.4,
            "is_registered": True,
            "category": {"id": 5, "name": "Tyre & Wheel Center"},
            "services": [
                {"service_name": "Puncture Repair", "price": "KSh 500 - 1,500"},
                {"service_name": "Wheel Alignment", "price": "KSh 2,500 - 4,500"},
                {"service_name": "Wheel Balancing", "price": "KSh 1,500 - 3,000"},
                {"service_name": "Tyre Replacement", "price": "KSh 6,000 - 30,000"}
            ]
        }
    ]

def create_user_profiles(conn):
    """Create user profiles for the social service"""
    cursor = conn.cursor()
    profiles_data = [
        {
            "user_id": 1,
            "username": "driveon_admin",
            "display_name": "DriveOn Admin",
            "bio": "Official DriveOn platform account. Your trusted mobility companion! 🚗✨",
            "profile_image_url": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
            "is_verified": True,
            "is_provider": False,
            "followers_count": 1250,
            "following_count": 50,
            "posts_count": 45
        },
        {
            "user_id": 2,
            "username": "premium_auto_karen",
            "display_name": "Premium Auto Services",
            "bio": "Luxury car specialists in Karen. Authorized service center for premium brands. Book your service today! 🏎️",
            "profile_image_url": "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=150&h=150&fit=crop",
            "is_verified": True,
            "is_provider": True,
            "provider_id": "864b62a2-1b85-45de-8a5c-4d3e0f9ac058",
            "followers_count": 890,
            "following_count": 25,
            "posts_count": 32
        },
        {
            "user_id": 3,
            "username": "quickfix_motors",
            "display_name": "QuickFix Motors",
            "bio": "Fast & reliable car repairs! Open 7 days a week with emergency services. Your car's best friend! 🔧",
            "profile_image_url": "https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=150&h=150&fit=crop",
            "is_verified": True,
            "is_provider": True,
            "provider_id": "bf851ac3-9745-4416-a110-771dd51d84cd",
            "followers_count": 650,
            "following_count": 30,
            "posts_count": 28
        },
        {
            "user_id": 4,
            "username": "autocare_kenya",
            "display_name": "AutoCare Kenya",
            "bio": "15+ years experience with European & Japanese vehicles. Certified technicians, quality service guaranteed! 🇰🇪",
            "profile_image_url": "https://images.unsplash.com/photo-1580414773893-0f8a0a4a0b0b?w=150&h=150&fit=crop",
            "is_verified": True,
            "is_provider": True,
            "provider_id": "9d896e1a-ed67-46b9-b33c-bcf6d519927f",
            "followers_count": 720,
            "following_count": 35,
            "posts_count": 41
        },
        {
            "user_id": 5,
            "username": "sparkle_auto_spa",
            "display_name": "Sparkle Auto Spa",
            "bio": "Premium car wash & detailing with eco-friendly products. Your car deserves the best! ✨🚗",
            "profile_image_url": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=150&h=150&fit=crop",
            "is_verified": True,
            "is_provider": True,
            "provider_id": "66fd2721-f5ec-421a-82db-147621ff05f4",
            "followers_count": 580,
            "following_count": 20,
            "posts_count": 35
        },
        {
            "user_id": 6,
            "username": "tyremax_kenya",
            "display_name": "TyreMax Kenya",
            "bio": "Leading tyre dealer with all major brands. Wheel alignment, balancing & puncture repair. Quality guaranteed! 🛞",
            "profile_image_url": "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=150&h=150&fit=crop",
            "is_verified": True,
            "is_provider": True,
            "provider_id": "9e5e7b0a-273f-4d34-8914-2c174e720a65",
            "followers_count": 420,
            "following_count": 15,
            "posts_count": 22
        }
    ]
    
    created_count = 0
    for profile in profiles_data:
        try:
            cursor.execute("""
                INSERT INTO social.user_profiles 
                (id, user_id, username, display_name, bio, profile_image_url, is_verified, 
                 is_provider, provider_id, followers_count, following_count, posts_count)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (user_id) DO NOTHING
            """, (
                str(uuid.uuid4()),
                profile["user_id"],
                profile["username"],
                profile["display_name"],
                profile["bio"],
                profile["profile_image_url"],
                profile["is_verified"],
                profile["is_provider"],
                profile.get("provider_id"),
                profile["followers_count"],
                profile["following_count"],
                profile["posts_count"]
            ))
            if cursor.rowcount > 0:
                created_count += 1
                print(f"✅ Created user profile: {profile['display_name']}")
            else:
                print(f"⚠️  User profile already exists: {profile['display_name']}")
        except Exception as e:
            print(f"❌ Error creating profile {profile['display_name']}: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_hashtags(conn):
    """Create popular hashtags for the social platform"""
    cursor = conn.cursor()
    hashtags_data = [
        {"name": "DriveOn", "posts_count": 45},
        {"name": "CarMaintenance", "posts_count": 38},
        {"name": "NairobiCars", "posts_count": 32},
        {"name": "AutoRepair", "posts_count": 28},
        {"name": "CarWash", "posts_count": 25},
        {"name": "TyreService", "posts_count": 22},
        {"name": "PremiumCars", "posts_count": 20},
        {"name": "QuickFix", "posts_count": 18},
        {"name": "SparkleAuto", "posts_count": 16},
        {"name": "TyreMax", "posts_count": 14},
        {"name": "CarTips", "posts_count": 30},
        {"name": "VehicleCare", "posts_count": 26},
        {"name": "KenyaCars", "posts_count": 24},
        {"name": "AutoSpa", "posts_count": 19},
        {"name": "CarDetailing", "posts_count": 17},
        {"name": "WheelAlignment", "posts_count": 15},
        {"name": "EngineOil", "posts_count": 13},
        {"name": "BrakeService", "posts_count": 12},
        {"name": "ACService", "posts_count": 11},
        {"name": "BatteryService", "posts_count": 10}
    ]
    
    created_count = 0
    for hashtag in hashtags_data:
        try:
            cursor.execute("""
                INSERT INTO social.hashtags (id, name, posts_count, last_used)
                VALUES (%s, %s, %s, NOW())
                ON CONFLICT (name) DO NOTHING
            """, (str(uuid.uuid4()), hashtag["name"], hashtag["posts_count"]))
            if cursor.rowcount > 0:
                created_count += 1
                print(f"✅ Created hashtag: #{hashtag['name']}")
            else:
                print(f"⚠️  Hashtag already exists: #{hashtag['name']}")
        except Exception as e:
            print(f"❌ Error creating hashtag #{hashtag['name']}: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_social_posts(conn):
    """Create diverse social posts with different types and content"""
    cursor = conn.cursor()
    
    # Get hashtags for posts
    cursor.execute("SELECT name FROM social.hashtags")
    available_hashtags = [row[0] for row in cursor.fetchall()]
    
    posts_data = [
        # DriveOn Admin Posts
        {
            "user_id": 1,
            "provider_id": None,
            "content": "Welcome to DriveOn Social Hub! 🎉 Connect with fellow car enthusiasts, discover trusted service providers, and share your automotive journey. #DriveOn #NairobiCars #CarCommunity",
            "media_urls": ["https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=600&fit=crop"],
            "hashtags": ["DriveOn", "NairobiCars", "CarCommunity"],
            "type": "image",
            "is_sponsored": False,
            "status": "published"
        },
        {
            "user_id": 1,
            "provider_id": None,
            "content": "🚗💡 Car Maintenance Tip of the Day: Regular oil changes are crucial for your engine's health! Most manufacturers recommend changing oil every 5,000-7,500 km. What's your oil change routine? #CarTips #CarMaintenance #DriveOn",
            "media_urls": [],
            "hashtags": ["CarTips", "CarMaintenance", "DriveOn"],
            "type": "text",
            "is_sponsored": False,
            "status": "published"
        },
        {
            "user_id": 1,
            "provider_id": None,
            "content": "📱 New Feature Alert! You can now book services directly through our social hub. Swipe up on provider posts to book instantly! #DriveOn #NewFeature #BookNow",
            "media_urls": ["https://videos.pexels.com/video-files/3195394/3195394-uhd_2560_1440_25fps.mp4"],
            "hashtags": ["DriveOn", "NewFeature", "BookNow"],
            "type": "video",
            "is_sponsored": False,
            "status": "published"
        },
        
        # Premium Auto Services Posts
        {
            "user_id": 2,
            "provider_id": "864b62a2-1b85-45de-8a5c-4d3e0f9ac058",
            "content": "✨ Before & After: Luxury ceramic coating transformation! This BMW X5 now has a mirror-like finish that will last for years. Book your ceramic coating service today! #PremiumCars #CeramicCoating #SparkleAuto #DriveOn",
            "media_urls": [
                "https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop",
                "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=800&h=600&fit=crop"
            ],
            "hashtags": ["PremiumCars", "CeramicCoating", "SparkleAuto", "DriveOn"],
            "type": "carousel",
            "is_sponsored": True,
            "sponsored_by": "864b62a2-1b85-45de-8a5c-4d3e0f9ac058",
            "status": "published"
        },
        {
            "user_id": 2,
            "provider_id": "864b62a2-1b85-45de-8a5c-4d3e0f9ac058",
            "content": "🏎️ Engine overhaul in progress! Our certified technicians are working on this Mercedes AMG engine. Quality work takes time, but the results speak for themselves. #EngineOverhaul #PremiumCars #AutoRepair #DriveOn",
            "media_urls": ["https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800&h=600&fit=crop"],
            "hashtags": ["EngineOverhaul", "PremiumCars", "AutoRepair", "DriveOn"],
            "type": "image",
            "is_sponsored": False,
            "status": "published"
        },
        
        # QuickFix Motors Posts
        {
            "user_id": 3,
            "provider_id": "bf851ac3-9745-4416-a110-771dd51d84cd",
            "content": "⚡ Emergency jump start service available 24/7! Don't let a dead battery ruin your day. Call us anytime for quick assistance. #QuickFix #JumpStart #EmergencyService #DriveOn",
            "media_urls": ["https://images.unsplash.com/photo-1580414773893-0f8a0a4a0b0b?w=800&h=600&fit=crop"],
            "hashtags": ["QuickFix", "JumpStart", "EmergencyService", "DriveOn"],
            "type": "image",
            "is_sponsored": True,
            "sponsored_by": "bf851ac3-9745-4416-a110-771dd51d84cd",
            "status": "published"
        },
        {
            "user_id": 3,
            "provider_id": "bf851ac3-9745-4416-a110-771dd51d84cd",
            "content": "🔋 Battery testing in progress! We use advanced diagnostic equipment to check your battery's health. Prevention is better than being stranded! #BatteryService #QuickFix #CarMaintenance #DriveOn",
            "media_urls": ["https://videos.pexels.com/video-files/3195394/3195394-uhd_2560_1440_25fps.mp4"],
            "hashtags": ["BatteryService", "QuickFix", "CarMaintenance", "DriveOn"],
            "type": "video",
            "is_sponsored": False,
            "status": "published"
        },
        
        # AutoCare Kenya Posts
        {
            "user_id": 4,
            "provider_id": "9d896e1a-ed67-46b9-b33c-bcf6d519927f",
            "content": "🇰🇪 Proud to serve Nairobi for 15+ years! Specializing in European and Japanese vehicles with certified technicians. Your trust is our foundation. #AutoCare #NairobiCars #15Years #DriveOn",
            "media_urls": ["https://images.unsplash.com/photo-1580414773893-0f8a0a4a0b0b?w=800&h=600&fit=crop"],
            "hashtags": ["AutoCare", "NairobiCars", "15Years", "DriveOn"],
            "type": "image",
            "is_sponsored": False,
            "status": "published"
        },
        {
            "user_id": 4,
            "provider_id": "9d896e1a-ed67-46b9-b33c-bcf6d519927f",
            "content": "🔧 Engine tune-up completed! This Toyota Camry is now running smoother than ever. Regular maintenance keeps your car reliable. Book your tune-up today! #EngineTuneUp #AutoRepair #CarMaintenance #DriveOn",
            "media_urls": ["https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800&h=600&fit=crop"],
            "hashtags": ["EngineTuneUp", "AutoRepair", "CarMaintenance", "DriveOn"],
            "type": "image",
            "is_sponsored": True,
            "sponsored_by": "9d896e1a-ed67-46b9-b33c-bcf6d519927f",
            "status": "published"
        },
        
        # Sparkle Auto Spa Posts
        {
            "user_id": 5,
            "provider_id": "66fd2721-f5ec-421a-82db-147621ff05f4",
            "content": "✨ Eco-friendly car wash in progress! We use biodegradable products that are safe for your car and the environment. Clean car, clean conscience! #CarWash #EcoFriendly #SparkleAuto #DriveOn",
            "media_urls": ["https://videos.pexels.com/video-files/3195394/3195394-uhd_2560_1440_25fps.mp4"],
            "hashtags": ["CarWash", "EcoFriendly", "SparkleAuto", "DriveOn"],
            "type": "video",
            "is_sponsored": False,
            "status": "published"
        },
        {
            "user_id": 5,
            "provider_id": "66fd2721-f5ec-421a-82db-147621ff05f4",
            "content": "🧽 Interior deep clean transformation! From dusty to pristine in just 2 hours. Your car's interior deserves the same care as the exterior. #InteriorClean #CarDetailing #AutoSpa #DriveOn",
            "media_urls": [
                "https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop",
                "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop"
            ],
            "hashtags": ["InteriorClean", "CarDetailing", "AutoSpa", "DriveOn"],
            "type": "carousel",
            "is_sponsored": True,
            "sponsored_by": "66fd2721-f5ec-421a-82db-147621ff05f4",
            "status": "published"
        },
        
        # TyreMax Kenya Posts
        {
            "user_id": 6,
            "provider_id": "9e5e7b0a-273f-4d34-8914-2c174e720a65",
            "content": "🛞 Wheel alignment in progress! Proper alignment ensures even tyre wear and better fuel efficiency. Don't ignore those steering vibrations! #WheelAlignment #TyreService #TyreMax #DriveOn",
            "media_urls": ["https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&h=600&fit=crop"],
            "hashtags": ["WheelAlignment", "TyreService", "TyreMax", "DriveOn"],
            "type": "image",
            "is_sponsored": False,
            "status": "published"
        },
        {
            "user_id": 6,
            "provider_id": "9e5e7b0a-273f-4d34-8914-2c174e720a65",
            "content": "🔧 Puncture repair completed in 15 minutes! Quality patch work that will last. Don't let a small puncture become a big problem. #PunctureRepair #TyreService #QuickService #DriveOn",
            "media_urls": ["https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&h=600&fit=crop"],
            "hashtags": ["PunctureRepair", "TyreService", "QuickService", "DriveOn"],
            "type": "image",
            "is_sponsored": True,
            "sponsored_by": "9e5e7b0a-273f-4d34-8914-2c174e720a65",
            "status": "published"
        }
    ]
    
    created_posts = []
    created_count = 0
    
    for post_data in posts_data:
        try:
            post_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO social.posts 
                (id, user_id, provider_id, content, media_urls, hashtags, type, 
                 is_sponsored, sponsored_by, status, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
            """, (
                post_id,
                post_data["user_id"],
                post_data.get("provider_id"),
                post_data["content"],
                json.dumps(post_data["media_urls"]),
                json.dumps(post_data["hashtags"]),
                post_data["type"],
                post_data["is_sponsored"],
                post_data.get("sponsored_by"),
                post_data["status"]
            ))
            
            created_posts.append(post_id)
            created_count += 1
            print(f"✅ Created post: {post_data['content'][:50]}...")
            
        except Exception as e:
            print(f"❌ Error creating post: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_posts, created_count

def create_stories(conn):
    """Create social stories for providers"""
    cursor = conn.cursor()
    
    stories_data = [
        {
            "user_id": 2,
            "provider_id": "864b62a2-1b85-45de-8a5c-4d3e0f9ac058",
            "content": "Behind the scenes: Luxury car detailing in progress! 🏎️✨",
            "media_url": "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=600&fit=crop",
            "type": "image"
        },
        {
            "user_id": 3,
            "provider_id": "bf851ac3-9745-4416-a110-771dd51d84cd",
            "content": "24/7 Emergency service available! Call us anytime ⚡",
            "media_url": "https://images.unsplash.com/photo-1580414773893-0f8a0a4a0b0b?w=400&h=600&fit=crop",
            "type": "image"
        },
        {
            "user_id": 4,
            "provider_id": "9d896e1a-ed67-46b9-b33c-bcf6d519927f",
            "content": "15 years of trusted service in Nairobi! 🇰🇪",
            "media_url": "https://images.unsplash.com/photo-1580414773893-0f8a0a4a0b0b?w=400&h=600&fit=crop",
            "type": "image"
        },
        {
            "user_id": 5,
            "provider_id": "66fd2721-f5ec-421a-82db-147621ff05f4",
            "content": "Eco-friendly products for a cleaner tomorrow! 🌱",
            "media_url": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=600&fit=crop",
            "type": "image"
        },
        {
            "user_id": 6,
            "provider_id": "9e5e7b0a-273f-4d34-8914-2c174e720a65",
            "content": "All major tyre brands available! 🛞",
            "media_url": "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=400&h=600&fit=crop",
            "type": "image"
        }
    ]
    
    created_stories = []
    created_count = 0
    
    for story_data in stories_data:
        try:
            story_id = str(uuid.uuid4())
            # Stories expire in 24 hours
            expires_at = datetime.now() + timedelta(hours=24)
            
            cursor.execute("""
                INSERT INTO social.stories 
                (id, user_id, provider_id, content, media_url, type, created_at, expires_at)
                VALUES (%s, %s, %s, %s, %s, %s, NOW(), %s)
            """, (
                story_id,
                story_data["user_id"],
                story_data["provider_id"],
                story_data["content"],
                story_data["media_url"],
                story_data["type"],
                expires_at
            ))
            
            created_stories.append(story_id)
            created_count += 1
            print(f"✅ Created story: {story_data['content'][:50]}...")
            
        except Exception as e:
            print(f"❌ Error creating story: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_stories, created_count

def create_comments(conn, post_ids):
    """Create comments on posts"""
    cursor = conn.cursor()
    
    comments_data = [
        {"post_id": 0, "user_id": 2, "content": "Welcome to the DriveOn family! 🎉"},
        {"post_id": 0, "user_id": 3, "content": "Excited to be part of this community!"},
        {"post_id": 0, "user_id": 4, "content": "Great platform for car enthusiasts! 👍"},
        {"post_id": 1, "user_id": 5, "content": "Great tip! I change mine every 5,000km religiously."},
        {"post_id": 1, "user_id": 6, "content": "What oil brand do you recommend?"},
        {"post_id": 2, "user_id": 2, "content": "This feature is amazing! So convenient! 🔥"},
        {"post_id": 3, "user_id": 1, "content": "That ceramic coating looks incredible! ✨"},
        {"post_id": 3, "user_id": 3, "content": "How long does ceramic coating last?"},
        {"post_id": 4, "user_id": 4, "content": "Quality work as always! 👏"},
        {"post_id": 5, "user_id": 5, "content": "QuickFix saved me last week! Great service! ⚡"},
        {"post_id": 5, "user_id": 1, "content": "24/7 service is a lifesaver!"},
        {"post_id": 6, "user_id": 6, "content": "Battery health is so important! Good reminder."},
        {"post_id": 7, "user_id": 2, "content": "15 years of excellence! Congratulations! 🎉"},
        {"post_id": 7, "user_id": 3, "content": "Trusted service provider in Nairobi!"},
        {"post_id": 8, "user_id": 4, "content": "That tune-up made a huge difference!"},
        {"post_id": 9, "user_id": 5, "content": "Eco-friendly approach is commendable! 🌱"},
        {"post_id": 9, "user_id": 6, "content": "Love the environmental consciousness!"},
        {"post_id": 10, "user_id": 1, "content": "Interior transformation is amazing! ✨"},
        {"post_id": 10, "user_id": 2, "content": "Professional work as expected!"},
        {"post_id": 11, "user_id": 3, "content": "Proper alignment is crucial for safety!"},
        {"post_id": 12, "user_id": 4, "content": "15 minutes for puncture repair is impressive!"},
        {"post_id": 12, "user_id": 5, "content": "Quality patch work! 👍"}
    ]
    
    created_count = 0
    
    for comment_data in comments_data:
        try:
            if comment_data["post_id"] < len(post_ids):
                comment_id = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO social.comments 
                    (id, post_id, user_id, content, created_at)
                    VALUES (%s, %s, %s, %s, NOW())
                """, (
                    comment_id,
                    post_ids[comment_data["post_id"]],
                    comment_data["user_id"],
                    comment_data["content"]
                ))
                created_count += 1
        except Exception as e:
            print(f"❌ Error creating comment: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_likes(conn, post_ids):
    """Create likes on posts and comments"""
    cursor = conn.cursor()
    
    # Create likes on posts
    created_count = 0
    
    # Each post gets likes from different users
    for i, post_id in enumerate(post_ids):
        # Random number of likes per post (5-15)
        num_likes = random.randint(5, 15)
        users_who_liked = random.sample(range(1, 7), min(num_likes, 6))
        
        for user_id in users_who_liked:
            try:
                cursor.execute("""
                    INSERT INTO social.likes (id, user_id, post_id, created_at)
                    VALUES (%s, %s, %s, NOW())
                    ON CONFLICT (user_id, post_id) DO NOTHING
                """, (str(uuid.uuid4()), user_id, post_id))
                if cursor.rowcount > 0:
                    created_count += 1
            except Exception as e:
                print(f"❌ Error creating like: {str(e)}")
    
    # Create likes on comments
    cursor.execute("SELECT id FROM social.comments LIMIT 10")
    comment_ids = [row[0] for row in cursor.fetchall()]
    
    for comment_id in comment_ids:
        # Random likes on comments (2-8)
        num_likes = random.randint(2, 8)
        users_who_liked = random.sample(range(1, 7), min(num_likes, 6))
        
        for user_id in users_who_liked:
            try:
                cursor.execute("""
                    INSERT INTO social.likes (id, user_id, comment_id, created_at)
                    VALUES (%s, %s, %s, NOW())
                    ON CONFLICT (user_id, comment_id) DO NOTHING
                """, (str(uuid.uuid4()), user_id, comment_id))
                if cursor.rowcount > 0:
                    created_count += 1
            except Exception as e:
                print(f"❌ Error creating comment like: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_shares(conn, post_ids):
    """Create shares of posts"""
    cursor = conn.cursor()
    
    created_count = 0
    
    # Each post gets some shares
    for post_id in post_ids:
        # Random number of shares per post (2-8)
        num_shares = random.randint(2, 8)
        users_who_shared = random.sample(range(1, 7), min(num_shares, 6))
        
        for user_id in users_who_shared:
            try:
                share_messages = [
                    "Check this out!",
                    "Great service!",
                    "Highly recommended!",
                    "Amazing work!",
                    "Must try!",
                    "Quality service!",
                    "Professional work!",
                    "Excellent results!"
                ]
                
                cursor.execute("""
                    INSERT INTO social.shares (id, user_id, post_id, message, shared_to, created_at)
                    VALUES (%s, %s, %s, %s, %s, NOW())
                """, (
                    str(uuid.uuid4()),
                    user_id,
                    post_id,
                    random.choice(share_messages),
                    "internal"
                ))
                created_count += 1
            except Exception as e:
                print(f"❌ Error creating share: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_follows(conn):
    """Create follow relationships between users"""
    cursor = conn.cursor()
    
    # Define follow relationships
    follow_relationships = [
        (2, 1), (3, 1), (4, 1), (5, 1), (6, 1),  # All providers follow admin
        (1, 2), (1, 3), (1, 4), (1, 5), (1, 6),  # Admin follows all providers
        (2, 3), (2, 4), (2, 5), (2, 6),          # Premium Auto follows others
        (3, 2), (3, 4), (3, 5), (3, 6),          # QuickFix follows others
        (4, 2), (4, 3), (4, 5), (4, 6),          # AutoCare follows others
        (5, 2), (5, 3), (5, 4), (5, 6),          # Sparkle Auto follows others
        (6, 2), (6, 3), (6, 4), (6, 5),          # TyreMax follows others
    ]
    
    created_count = 0
    
    for follower_id, following_id in follow_relationships:
        try:
            cursor.execute("""
                INSERT INTO social.follows (id, follower_id, following_id, created_at)
                VALUES (%s, %s, %s, NOW())
                ON CONFLICT (follower_id, following_id) DO NOTHING
            """, (str(uuid.uuid4()), follower_id, following_id))
            if cursor.rowcount > 0:
                created_count += 1
        except Exception as e:
            print(f"❌ Error creating follow: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_story_views(conn, story_ids):
    """Create story views"""
    cursor = conn.cursor()
    
    created_count = 0
    
    for story_id in story_ids:
        # Random number of views per story (3-10)
        num_views = random.randint(3, 10)
        users_who_viewed = random.sample(range(1, 7), min(num_views, 6))
        
        for user_id in users_who_viewed:
            try:
                cursor.execute("""
                    INSERT INTO social.story_views (id, story_id, user_id, viewed_at)
                    VALUES (%s, %s, %s, NOW())
                    ON CONFLICT (story_id, user_id) DO NOTHING
                """, (str(uuid.uuid4()), story_id, user_id))
                if cursor.rowcount > 0:
                    created_count += 1
            except Exception as e:
                print(f"❌ Error creating story view: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_post_analytics(conn, post_ids):
    """Create analytics data for posts"""
    cursor = conn.cursor()
    
    created_count = 0
    
    for post_id in post_ids:
        try:
            # Generate random analytics data
            views = random.randint(50, 500)
            likes = random.randint(5, 50)
            comments = random.randint(2, 20)
            shares = random.randint(1, 15)
            
            cursor.execute("""
                INSERT INTO social.post_analytics 
                (id, post_id, views, likes, comments, shares, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, NOW(), NOW())
            """, (
                str(uuid.uuid4()),
                post_id,
                views,
                likes,
                comments,
                shares
            ))
            created_count += 1
        except Exception as e:
            print(f"❌ Error creating analytics: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_notifications(conn):
    """Create sample notifications"""
    cursor = conn.cursor()
    
    notifications_data = [
        {
            "user_id": 1,
            "type": "follow",
            "title": "New Follower",
            "message": "Premium Auto Services started following you",
            "related_user_id": 2
        },
        {
            "user_id": 1,
            "type": "like",
            "title": "Post Liked",
            "message": "QuickFix Motors liked your post about car maintenance tips",
            "related_user_id": 3,
            "related_post_id": "sample_post_id"
        },
        {
            "user_id": 2,
            "type": "comment",
            "title": "New Comment",
            "message": "DriveOn Admin commented on your ceramic coating post",
            "related_user_id": 1,
            "related_post_id": "sample_post_id"
        },
        {
            "user_id": 3,
            "type": "share",
            "title": "Post Shared",
            "message": "AutoCare Kenya shared your emergency service post",
            "related_user_id": 4,
            "related_post_id": "sample_post_id"
        }
    ]
    
    created_count = 0
    
    for notification in notifications_data:
        try:
            cursor.execute("""
                INSERT INTO social.notifications 
                (id, user_id, type, title, message, related_user_id, 
                 related_post_id, is_read, is_sent, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
            """, (
                str(uuid.uuid4()),
                notification["user_id"],
                notification["type"],
                notification["title"],
                notification["message"],
                notification.get("related_user_id"),
                notification.get("related_post_id"),
                random.choice([True, False]),  # Random read status
                True  # All notifications are sent
            ))
            created_count += 1
        except Exception as e:
            print(f"❌ Error creating notification: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def main():
    """Main function to run the social service seeding script"""
    print("🌱 Starting Social Service Database Seeding...")
    print("=" * 60)
    
    try:
        # Get database connection
        conn = get_db_connection()
        
        # Create social schema
        print("\n📋 Creating Social Schema...")
        create_social_schema(conn)
        
        # Create user profiles
        print("\n👤 Creating User Profiles...")
        profiles_count = create_user_profiles(conn)
        
        # Create hashtags
        print("\n#️⃣ Creating Hashtags...")
        hashtags_count = create_hashtags(conn)
        
        # Create social posts
        print("\n📝 Creating Social Posts...")
        post_ids, posts_count = create_social_posts(conn)
        
        # Create stories
        print("\n📖 Creating Stories...")
        story_ids, stories_count = create_stories(conn)
        
        # Create comments
        print("\n💬 Creating Comments...")
        comments_count = create_comments(conn, post_ids)
        
        # Create likes
        print("\n❤️ Creating Likes...")
        likes_count = create_likes(conn, post_ids)
        
        # Create shares
        print("\n🔄 Creating Shares...")
        shares_count = create_shares(conn, post_ids)
        
        # Create follows
        print("\n👥 Creating Follow Relationships...")
        follows_count = create_follows(conn)
        
        # Create story views
        print("\n👀 Creating Story Views...")
        story_views_count = create_story_views(conn, story_ids)
        
        # Create post analytics
        print("\n📊 Creating Post Analytics...")
        analytics_count = create_post_analytics(conn, post_ids)
        
        # Create notifications
        print("\n🔔 Creating Notifications...")
        notifications_count = create_notifications(conn)
        
        print("\n" + "=" * 60)
        print("🎉 Social Service Database Seeding Completed Successfully!")
        print(f"📊 Summary:")
        print(f"   - User Profiles: {profiles_count} created")
        print(f"   - Hashtags: {hashtags_count} created")
        print(f"   - Social Posts: {posts_count} created")
        print(f"   - Stories: {stories_count} created")
        print(f"   - Comments: {comments_count} created")
        print(f"   - Likes: {likes_count} created")
        print(f"   - Shares: {shares_count} created")
        print(f"   - Follows: {follows_count} created")
        print(f"   - Story Views: {story_views_count} created")
        print(f"   - Analytics: {analytics_count} created")
        print(f"   - Notifications: {notifications_count} created")
        print(f"\n🚀 Your DriveOn Social Hub is now ready with realistic data!")
        
    except Exception as e:
        print(f"❌ Error during seeding: {str(e)}")
        raise
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
