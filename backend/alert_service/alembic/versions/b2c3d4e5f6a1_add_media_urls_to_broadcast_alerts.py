"""add media_urls to broadcast_alerts

Revision ID: b2c3d4e5f6a1
Revises: a1b2c3d4e5f6
Create Date: 2026-03-30

"""
from alembic import op

revision = 'b2c3d4e5f6a1'
down_revision = 'a1b2c3d4e5f6'
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        ALTER TABLE alerts.broadcast_alerts
        ADD COLUMN IF NOT EXISTS media_urls JSONB NOT NULL DEFAULT '[]'::jsonb;
    """)


def downgrade():
    op.execute("""
        ALTER TABLE alerts.broadcast_alerts
        DROP COLUMN IF EXISTS media_urls;
    """)
