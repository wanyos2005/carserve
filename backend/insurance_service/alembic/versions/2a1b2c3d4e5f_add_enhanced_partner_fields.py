"""add_enhanced_partner_fields

Revision ID: 2a1b2c3d4e5f
Revises: 1ed6d9d8ffb1
Create Date: 2025-01-15 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '2a1b2c3d4e5f'
down_revision: Union[str, None] = '1ed6d9d8ffb1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add enhanced partner fields to insurance_partners table"""
    
    # Add Secondary Information (Decision Factors) columns
    op.add_column('insurance_partners', 
                  sa.Column('customer_rating', sa.Integer(), nullable=True),
                  schema='insurance')
    
    op.add_column('insurance_partners', 
                  sa.Column('total_reviews', sa.Integer(), nullable=True),
                  schema='insurance')
    
    op.add_column('insurance_partners', 
                  sa.Column('claims_processing_time', sa.String(50), nullable=True),
                  schema='insurance')
    
    op.add_column('insurance_partners', 
                  sa.Column('policy_validity_period', sa.String(50), nullable=True),
                  schema='insurance')
    
    op.add_column('insurance_partners', 
                  sa.Column('special_features', sa.JSON(), nullable=True),
                  schema='insurance')
    
    # Add Tertiary Information (Nice to Have) columns
    op.add_column('insurance_partners', 
                  sa.Column('logo_url', sa.String(500), nullable=True),
                  schema='insurance')
    
    op.add_column('insurance_partners', 
                  sa.Column('website_url', sa.String(500), nullable=True),
                  schema='insurance')
    
    op.add_column('insurance_partners', 
                  sa.Column('established_year', sa.Integer(), nullable=True),
                  schema='insurance')
    
    op.add_column('insurance_partners', 
                  sa.Column('market_share', sa.String(20), nullable=True),
                  schema='insurance')
    
    op.add_column('insurance_partners', 
                  sa.Column('awards', sa.JSON(), nullable=True),
                  schema='insurance')
    
    # Add sample enhanced data for existing partners
    # Update KIC with enhanced data
    op.execute("""
        UPDATE insurance.insurance_partners 
        SET 
            customer_rating = 48,  -- 4.8/5.0
            total_reviews = 1250,
            claims_processing_time = '24-48 hours',
            policy_validity_period = '12 months',
            special_features = '["24/7 customer support", "Mobile app available", "Online claims filing", "Cashless garages"]',
            logo_url = 'https://cdn.kic.co.ke/logo.png',
            website_url = 'https://www.kic.co.ke',
            established_year = 1985,
            market_share = '15%',
            awards = '["Best Insurance Company 2023", "Customer Service Excellence Award"]'
        WHERE code = 'KIC';
    """)
    
    # Update APA with enhanced data
    op.execute("""
        UPDATE insurance.insurance_partners 
        SET 
            customer_rating = 46,  -- 4.6/5.0
            total_reviews = 980,
            claims_processing_time = '48-72 hours',
            policy_validity_period = '12 months',
            special_features = '["24/7 roadside assistance", "Mobile app", "Online policy management"]',
            logo_url = 'https://cdn.apa.co.ke/logo.png',
            website_url = 'https://www.apa.co.ke',
            established_year = 1992,
            market_share = '12%',
            awards = '["Innovation in Insurance 2023"]'
        WHERE code = 'APA';
    """)
    
    # Update CIC with enhanced data
    op.execute("""
        UPDATE insurance.insurance_partners 
        SET 
            customer_rating = 44,  -- 4.4/5.0
            total_reviews = 750,
            claims_processing_time = '72-96 hours',
            policy_validity_period = '12 months',
            special_features = '["Budget-friendly premiums", "Basic coverage options"]',
            logo_url = 'https://cdn.cic.co.ke/logo.png',
            website_url = 'https://www.cic.co.ke',
            established_year = 2000,
            market_share = '8%',
            awards = '[]'
        WHERE code = 'CIC';
    """)


def downgrade() -> None:
    """Remove enhanced partner fields from insurance_partners table"""
    
    # Remove Tertiary Information columns
    op.drop_column('insurance_partners', 'awards', schema='insurance')
    op.drop_column('insurance_partners', 'market_share', schema='insurance')
    op.drop_column('insurance_partners', 'established_year', schema='insurance')
    op.drop_column('insurance_partners', 'website_url', schema='insurance')
    op.drop_column('insurance_partners', 'logo_url', schema='insurance')
    
    # Remove Secondary Information columns
    op.drop_column('insurance_partners', 'special_features', schema='insurance')
    op.drop_column('insurance_partners', 'policy_validity_period', schema='insurance')
    op.drop_column('insurance_partners', 'claims_processing_time', schema='insurance')
    op.drop_column('insurance_partners', 'total_reviews', schema='insurance')
    op.drop_column('insurance_partners', 'customer_rating', schema='insurance')
