"""baseline

Revision ID: 4b256f9ea6f3
Revises: 
Create Date: 2025-11-03 12:29:54.240280

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '4b256f9ea6f3'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema - creates all tables from scratch."""
    # Create schema if it doesn't exist
    op.execute(sa.text("CREATE SCHEMA IF NOT EXISTS loyalty"))
    
    # Create loyalty_accounts table
    op.create_table(
        'loyalty_accounts',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('points_balance', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('lifetime_points_earned', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('lifetime_points_spent', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('tier', sa.String(length=20), nullable=False, server_default='bronze'),
        sa.Column('tier_points_threshold', sa.Integer(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('joined_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('last_activity_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        schema='loyalty'
    )
    op.create_index(op.f('ix_loyalty_loyalty_accounts_user_id'), 'loyalty_accounts', ['user_id'], unique=True, schema='loyalty')
    
    # Create loyalty_transactions table
    op.create_table(
        'loyalty_transactions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('account_id', sa.String(), nullable=False),
        sa.Column('points_delta', sa.Integer(), nullable=False),
        sa.Column('points_balance_after', sa.Integer(), nullable=False),
        sa.Column('transaction_type', sa.String(length=50), nullable=False),
        sa.Column('transaction_reason', sa.String(length=255), nullable=True),
        sa.Column('reference_type', sa.String(length=50), nullable=True),
        sa.Column('reference_id', sa.String(), nullable=True),
        sa.Column('idempotency_key', sa.String(), nullable=True),
        sa.Column('provider_id', sa.String(), nullable=True),
        sa.Column('service_id', sa.String(), nullable=True),
        sa.Column('amount_spent', sa.Integer(), nullable=True),
        sa.Column('expires_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('is_expired', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('extra_metadata', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['account_id'], ['loyalty.loyalty_accounts.id'], ),
        sa.PrimaryKeyConstraint('id'),
        schema='loyalty'
    )
    op.create_index(op.f('ix_loyalty_loyalty_transactions_account_id'), 'loyalty_transactions', ['account_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_transactions_created_at'), 'loyalty_transactions', ['created_at'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_transactions_expires_at'), 'loyalty_transactions', ['expires_at'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_transactions_idempotency_key'), 'loyalty_transactions', ['idempotency_key'], unique=True, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_transactions_is_expired'), 'loyalty_transactions', ['is_expired'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_transactions_provider_id'), 'loyalty_transactions', ['provider_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_transactions_reference_id'), 'loyalty_transactions', ['reference_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_transactions_reference_type'), 'loyalty_transactions', ['reference_type'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_transactions_transaction_type'), 'loyalty_transactions', ['transaction_type'], unique=False, schema='loyalty')
    
    # Create loyalty_rules table
    op.create_table(
        'loyalty_rules',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('provider_id', sa.String(), nullable=True),
        sa.Column('provider_category_id', sa.Integer(), nullable=True),
        sa.Column('service_id', sa.String(), nullable=True),
        sa.Column('service_category_id', sa.Integer(), nullable=True),
        sa.Column('base_points_per_kes', sa.Numeric(precision=10, scale=4), nullable=False, server_default='0.01'),
        sa.Column('multiplier', sa.Numeric(precision=5, scale=2), nullable=False, server_default='1.0'),
        sa.Column('min_amount', sa.Integer(), nullable=True),
        sa.Column('max_points_per_transaction', sa.Integer(), nullable=True),
        sa.Column('tier_multipliers', sa.JSON(), nullable=True),
        sa.Column('valid_from', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('valid_until', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('priority', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('conditions', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        schema='loyalty'
    )
    op.create_index(op.f('ix_loyalty_loyalty_rules_provider_category_id'), 'loyalty_rules', ['provider_category_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_rules_provider_id'), 'loyalty_rules', ['provider_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_rules_service_category_id'), 'loyalty_rules', ['service_category_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_rules_service_id'), 'loyalty_rules', ['service_id'], unique=False, schema='loyalty')
    
    # Create rewards table
    op.create_table(
        'rewards',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('reward_type', sa.String(length=50), nullable=False),
        sa.Column('points_cost', sa.Integer(), nullable=False),
        sa.Column('discount_percentage', sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column('discount_amount', sa.Integer(), nullable=True),
        sa.Column('cashback_amount', sa.Integer(), nullable=True),
        sa.Column('voucher_code_template', sa.String(length=255), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('total_available', sa.Integer(), nullable=True),
        sa.Column('total_redeemed', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('max_redemptions_per_user', sa.Integer(), nullable=True),
        sa.Column('min_tier_required', sa.String(length=20), nullable=True),
        sa.Column('valid_from', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('valid_until', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('image_url', sa.String(length=512), nullable=True),
        sa.Column('funding_model', sa.String(length=20), nullable=False, server_default='platform'),
        sa.Column('funding_provider_id', sa.String(), nullable=True),
        sa.Column('co_fund_split_pct', sa.Integer(), nullable=True),
        sa.Column('extra_metadata', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        schema='loyalty'
    )
    
    # Create loyalty_redemptions table
    op.create_table(
        'loyalty_redemptions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('account_id', sa.String(), nullable=False),
        sa.Column('reward_id', sa.String(), nullable=False),
        sa.Column('points_spent', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='pending'),
        sa.Column('reward_name', sa.String(length=255), nullable=False),
        sa.Column('reward_type', sa.String(length=50), nullable=False),
        sa.Column('reward_value', sa.JSON(), nullable=True),
        sa.Column('voucher_code', sa.String(length=255), nullable=True),
        sa.Column('is_consumed', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('validated_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('validated_by_provider_id', sa.String(), nullable=True),
        sa.Column('fulfilled_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('fulfilled_by', sa.String(), nullable=True),
        sa.Column('fulfillment_notes', sa.Text(), nullable=True),
        sa.Column('expires_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('cancelled_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('cancellation_reason', sa.Text(), nullable=True),
        sa.Column('settlement_status', sa.String(length=20), nullable=False, server_default='pending'),
        sa.Column('settlement_provider_amount', sa.Integer(), nullable=True),
        sa.Column('settlement_platform_amount', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['account_id'], ['loyalty.loyalty_accounts.id'], ),
        sa.ForeignKeyConstraint(['reward_id'], ['loyalty.rewards.id'], ),
        sa.PrimaryKeyConstraint('id'),
        schema='loyalty'
    )
    op.create_index(op.f('ix_loyalty_loyalty_redemptions_account_id'), 'loyalty_redemptions', ['account_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_redemptions_created_at'), 'loyalty_redemptions', ['created_at'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_redemptions_is_consumed'), 'loyalty_redemptions', ['is_consumed'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_redemptions_reward_id'), 'loyalty_redemptions', ['reward_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_redemptions_validated_by_provider_id'), 'loyalty_redemptions', ['validated_by_provider_id'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_loyalty_redemptions_voucher_code'), 'loyalty_redemptions', ['voucher_code'], unique=True, schema='loyalty')
    
    # Create provider_loyalty_configs table
    op.create_table(
        'provider_loyalty_configs',
        sa.Column('provider_id', sa.String(), nullable=False),
        sa.Column('is_participating', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('point_multiplier', sa.Numeric(precision=5, scale=2), nullable=False, server_default='1.0'),
        sa.Column('participation_tier', sa.String(length=20), nullable=True),
        sa.Column('monthly_point_budget', sa.Integer(), nullable=True),
        sa.Column('points_awarded_this_month', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('current_month_start', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('billing_plan', sa.String(length=50), nullable=False, server_default='free'),
        sa.Column('billing_rate_per_point', sa.Numeric(precision=10, scale=4), nullable=True),
        sa.Column('monthly_subscription_fee', sa.Integer(), nullable=True),
        sa.Column('extra_metadata', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('participation_enabled_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('provider_id'),
        schema='loyalty'
    )
    op.create_index(op.f('ix_loyalty_provider_loyalty_configs_is_participating'), 'provider_loyalty_configs', ['is_participating'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_provider_loyalty_configs_participation_tier'), 'provider_loyalty_configs', ['participation_tier'], unique=False, schema='loyalty')
    op.create_index(op.f('ix_loyalty_provider_loyalty_configs_provider_id'), 'provider_loyalty_configs', ['provider_id'], unique=False, schema='loyalty')


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_loyalty_provider_loyalty_configs_provider_id'), table_name='provider_loyalty_configs', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_provider_loyalty_configs_participation_tier'), table_name='provider_loyalty_configs', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_provider_loyalty_configs_is_participating'), table_name='provider_loyalty_configs', schema='loyalty')
    op.drop_table('provider_loyalty_configs', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_redemptions_voucher_code'), table_name='loyalty_redemptions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_redemptions_validated_by_provider_id'), table_name='loyalty_redemptions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_redemptions_reward_id'), table_name='loyalty_redemptions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_redemptions_is_consumed'), table_name='loyalty_redemptions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_redemptions_created_at'), table_name='loyalty_redemptions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_redemptions_account_id'), table_name='loyalty_redemptions', schema='loyalty')
    op.drop_table('loyalty_redemptions', schema='loyalty')
    op.drop_table('rewards', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_rules_service_id'), table_name='loyalty_rules', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_rules_service_category_id'), table_name='loyalty_rules', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_rules_provider_id'), table_name='loyalty_rules', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_rules_provider_category_id'), table_name='loyalty_rules', schema='loyalty')
    op.drop_table('loyalty_rules', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_transaction_type'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_reference_type'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_reference_id'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_provider_id'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_is_expired'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_idempotency_key'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_expires_at'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_created_at'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_transactions_account_id'), table_name='loyalty_transactions', schema='loyalty')
    op.drop_table('loyalty_transactions', schema='loyalty')
    op.drop_index(op.f('ix_loyalty_loyalty_accounts_user_id'), table_name='loyalty_accounts', schema='loyalty')
    op.drop_table('loyalty_accounts', schema='loyalty')
    # Drop schema if empty (optional - you may want to keep it)
    # op.execute(sa.text("DROP SCHEMA IF EXISTS loyalty"))
