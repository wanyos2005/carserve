#!/usr/bin/env python3
"""
Database migration script to create enhanced insurance tables
Run this script to add the new insurance tables to the database
"""

import sys
import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from core.config import DATABASE_URL
from models.insurance import Base, Insurance_Policy, Insurance_Claim, Risk_Score, Insurance_Partner, Data_Feed_Log

def create_insurance_schema():
    """Create the insurance schema and tables"""
    
    print("🚗 DriveOn Insurance Service - Database Migration")
    print("=" * 50)
    
    # Create database connection
    engine = create_engine(DATABASE_URL)
    
    try:
        with engine.connect() as connection:
            # Create insurance schema if it doesn't exist
            print("📋 Creating insurance schema...")
            connection.execute(text("CREATE SCHEMA IF NOT EXISTS insurance;"))
            connection.commit()
            print("✅ Insurance schema created successfully")
            
            # Create all tables
            print("📋 Creating insurance tables...")
            Base.metadata.create_all(bind=engine)
            print("✅ All insurance tables created successfully")
            
            # Create indexes for better performance
            print("📋 Creating indexes...")
            
            # Indexes for insurance_policies
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_policies_owner_id 
                ON insurance.insurance_policies(owner_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_policies_vehicle_id 
                ON insurance.insurance_policies(vehicle_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_policies_provider_id 
                ON insurance.insurance_policies(provider_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_policies_status 
                ON insurance.insurance_policies(status);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_policies_expiry_date 
                ON insurance.insurance_policies(expiry_date);
            """))
            
            # Indexes for insurance_claims
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_claims_policy_id 
                ON insurance.insurance_claims(policy_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_claims_vehicle_id 
                ON insurance.insurance_claims(vehicle_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_claims_user_id 
                ON insurance.insurance_claims(user_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_claims_status 
                ON insurance.insurance_claims(status);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_claims_claim_type 
                ON insurance.insurance_claims(claim_type);
            """))
            
            # Indexes for risk_scores
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_risk_scores_vehicle_id 
                ON insurance.risk_scores(vehicle_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_risk_scores_user_id 
                ON insurance.risk_scores(user_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_risk_scores_last_updated 
                ON insurance.risk_scores(last_updated);
            """))
            
            # Indexes for insurance_partners
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_partners_code 
                ON insurance.insurance_partners(code);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_insurance_partners_is_active 
                ON insurance.insurance_partners(is_active);
            """))
            
            # Indexes for data_feed_logs
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_data_feed_logs_partner_id 
                ON insurance.data_feed_logs(partner_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_data_feed_logs_vehicle_id 
                ON insurance.data_feed_logs(vehicle_id);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_data_feed_logs_feed_type 
                ON insurance.data_feed_logs(feed_type);
            """))
            
            connection.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_data_feed_logs_status 
                ON insurance.data_feed_logs(status);
            """))
            
            connection.commit()
            print("✅ All indexes created successfully")
            
            # Insert sample insurance partners
            print("📋 Inserting sample insurance partners...")
            
            sample_partners = [
                {
                    'name': 'Kenya Insurance Company',
                    'code': 'KIC',
                    'api_endpoint': 'https://api.kic.co.ke',
                    'webhook_url': 'https://api.kic.co.ke/webhooks',
                    'supports_quotes': True,
                    'supports_claims': True,
                    'supports_data_feeds': True,
                    'commission_rate': 10,
                    'contact_info': {
                        'email': 'partnerships@kic.co.ke',
                        'phone': '+254 20 123 4567'
                    },
                    'supported_coverage_types': ['comprehensive', 'third_party', 'fire_theft']
                },
                {
                    'name': 'APA Insurance',
                    'code': 'APA',
                    'api_endpoint': 'https://api.apa.co.ke',
                    'webhook_url': 'https://api.apa.co.ke/webhooks',
                    'supports_quotes': True,
                    'supports_claims': True,
                    'supports_data_feeds': True,
                    'commission_rate': 12,
                    'contact_info': {
                        'email': 'partnerships@apa.co.ke',
                        'phone': '+254 20 234 5678'
                    },
                    'supported_coverage_types': ['comprehensive', 'third_party', 'fire_theft', 'motor_commercial']
                },
                {
                    'name': 'CIC Insurance',
                    'code': 'CIC',
                    'api_endpoint': 'https://api.cic.co.ke',
                    'webhook_url': 'https://api.cic.co.ke/webhooks',
                    'supports_quotes': True,
                    'supports_claims': True,
                    'supports_data_feeds': True,
                    'commission_rate': 8,
                    'contact_info': {
                        'email': 'partnerships@cic.co.ke',
                        'phone': '+254 20 345 6789'
                    },
                    'supported_coverage_types': ['comprehensive', 'third_party']
                }
            ]
            
            Session = sessionmaker(bind=engine)
            session = Session()
            
            for partner_data in sample_partners:
                # Check if partner already exists
                existing_partner = session.query(Insurance_Partner).filter(
                    Insurance_Partner.code == partner_data['code']
                ).first()
                
                if not existing_partner:
                    partner = Insurance_Partner(**partner_data)
                    session.add(partner)
                    print(f"✅ Added partner: {partner_data['name']}")
                else:
                    print(f"⚠️  Partner already exists: {partner_data['name']}")
            
            session.commit()
            session.close()
            print("✅ Sample insurance partners inserted successfully")
            
            print("\n🎉 Insurance service database migration completed successfully!")
            print("\n📊 Created tables:")
            print("   • insurance_policies (enhanced)")
            print("   • insurance_claims")
            print("   • risk_scores")
            print("   • insurance_partners")
            print("   • data_feed_logs")
            print("\n🔗 Next steps:")
            print("   1. Start the insurance service: docker compose up insurance-service")
            print("   2. Test the API endpoints at: http://localhost:8005/docs")
            print("   3. Create your first insurance policy")
            print("   4. Set up risk scoring for vehicles")
            
    except Exception as e:
        print(f"❌ Error during migration: {str(e)}")
        raise

if __name__ == "__main__":
    create_insurance_schema()
