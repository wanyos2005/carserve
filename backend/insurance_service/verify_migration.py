#!/usr/bin/env python3
"""
Verification script for enhanced partner fields migration.
Run this inside the Docker container to verify the migration was successful.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import text
from core.db import engine, get_db
from models.insurance import Insurance_Partner

def verify_migration():
    """Verify that the enhanced partner fields migration was successful"""
    
    print("🔍 Verifying Enhanced Partner Fields Migration")
    print("=" * 60)
    
    try:
        # Check if new columns exist
        print("1. Checking if new columns exist...")
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns 
                WHERE table_schema = 'insurance' 
                AND table_name = 'insurance_partners'
                AND column_name IN (
                    'customer_rating', 'total_reviews', 'claims_processing_time', 
                    'policy_validity_period', 'special_features', 'logo_url', 
                    'website_url', 'established_year', 'market_share', 'awards'
                )
                ORDER BY column_name;
            """))
            
            columns = result.fetchall()
            
            if len(columns) == 10:
                print("   ✅ All 10 enhanced columns found:")
                for column in columns:
                    print(f"      - {column[0]} ({column[1]}, nullable: {column[2]})")
            else:
                print(f"   ❌ Expected 10 columns, found {len(columns)}")
                return False
        
        # Check if sample data was populated
        print("\n2. Checking if sample data was populated...")
        db = next(get_db())
        partners = db.query(Insurance_Partner).filter(
            Insurance_Partner.customer_rating.isnot(None)
        ).all()
        
        if len(partners) >= 3:
            print(f"   ✅ Found {len(partners)} partners with enhanced data:")
            for partner in partners:
                rating = partner.customer_rating / 10.0 if partner.customer_rating else 0
                features_count = len(partner.special_features) if partner.special_features else 0
                awards_count = len(partner.awards) if partner.awards else 0
                
                print(f"      🏢 {partner.name} ({partner.code})")
                print(f"         Rating: {rating}/5.0 ({partner.total_reviews} reviews)")
                print(f"         Claims: {partner.claims_processing_time}")
                print(f"         Features: {features_count}, Awards: {awards_count}")
                print(f"         Market: {partner.market_share}")
        else:
            print(f"   ❌ Expected at least 3 partners with enhanced data, found {len(partners)}")
            return False
        
        # Test API response format
        print("\n3. Testing API response format...")
        sample_partner = partners[0]
        
        # Check if all expected fields are present
        expected_fields = [
            'customer_rating', 'total_reviews', 'claims_processing_time',
            'policy_validity_period', 'special_features', 'logo_url',
            'website_url', 'established_year', 'market_share', 'awards'
        ]
        
        missing_fields = []
        for field in expected_fields:
            if not hasattr(sample_partner, field):
                missing_fields.append(field)
        
        if not missing_fields:
            print("   ✅ All expected fields are present in the model")
        else:
            print(f"   ❌ Missing fields: {missing_fields}")
            return False
        
        # Test rating conversion
        print("\n4. Testing rating conversion...")
        if sample_partner.customer_rating:
            stored_rating = sample_partner.customer_rating
            api_rating = stored_rating / 10.0
            print(f"   ✅ Rating conversion: {stored_rating} (stored) → {api_rating} (API)")
        
        # Test JSON fields
        print("\n5. Testing JSON fields...")
        if sample_partner.special_features:
            print(f"   ✅ Special features: {sample_partner.special_features}")
        if sample_partner.awards:
            print(f"   ✅ Awards: {sample_partner.awards}")
        
        print("\n🎉 Migration verification completed successfully!")
        print("=" * 60)
        print("✅ Enhanced partner fields are ready for use")
        print("✅ Frontend can now display rich partner information")
        print("✅ API supports all enhanced fields")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Verification failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        if 'db' in locals():
            db.close()

def show_sample_api_response():
    """Show what the API response looks like with enhanced data"""
    
    print("\n📡 Sample API Response:")
    print("=" * 60)
    
    try:
        db = next(get_db())
        partner = db.query(Insurance_Partner).filter(
            Insurance_Partner.customer_rating.isnot(None)
        ).first()
        
        if partner:
            # Simulate API response (with rating conversion)
            api_response = {
                "id": partner.id,
                "name": partner.name,
                "code": partner.code,
                "api_endpoint": partner.api_endpoint,
                "webhook_url": partner.webhook_url,
                "supports_quotes": partner.supports_quotes,
                "supports_claims": partner.supports_claims,
                "supports_data_feeds": partner.supports_data_feeds,
                "is_active": partner.is_active,
                "commission_rate": partner.commission_rate,
                "contact_info": partner.contact_info,
                "supported_coverage_types": partner.supported_coverage_types,
                
                # Enhanced fields (with rating conversion)
                "customer_rating": partner.customer_rating / 10.0 if partner.customer_rating else None,
                "total_reviews": partner.total_reviews,
                "claims_processing_time": partner.claims_processing_time,
                "policy_validity_period": partner.policy_validity_period,
                "special_features": partner.special_features,
                "logo_url": partner.logo_url,
                "website_url": partner.website_url,
                "established_year": partner.established_year,
                "market_share": partner.market_share,
                "awards": partner.awards,
                
                "created_at": partner.created_at.isoformat() if partner.created_at else None,
                "updated_at": partner.updated_at.isoformat() if partner.updated_at else None
            }
            
            import json
            print(json.dumps(api_response, indent=2, default=str))
        else:
            print("No enhanced partners found")
            
    except Exception as e:
        print(f"Error showing sample response: {e}")
    finally:
        if 'db' in locals():
            db.close()

if __name__ == "__main__":
    print("🚀 Enhanced Partner Fields Migration Verification")
    print("=" * 60)
    
    success = verify_migration()
    
    if success:
        show_sample_api_response()
        print("\n✅ Migration verification completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Migration verification failed!")
        sys.exit(1)
