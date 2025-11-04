"""add_rating_request_and_app_download_alert_types

Revision ID: 48d05b247c5c
Revises: ef5c394342e2
Create Date: 2025-11-04 11:01:21.020568

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '48d05b247c5c'
down_revision: Union[str, Sequence[str], None] = 'ef5c394342e2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add new enum values to alerttype enum
    # Note: The enum type is in the 'public' schema, not 'alerts' schema
    # PostgreSQL doesn't support IF NOT EXISTS for ALTER TYPE ADD VALUE,
    # so we check if the value exists first
    op.execute("""
        DO $$ 
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_enum e
                JOIN pg_type t ON e.enumtypid = t.oid
                JOIN pg_namespace n ON t.typnamespace = n.oid
                WHERE e.enumlabel = 'APP_DOWNLOAD_PROMPT' 
                AND t.typname = 'alerttype'
                AND n.nspname = 'public'
            ) THEN
                ALTER TYPE alerttype ADD VALUE 'APP_DOWNLOAD_PROMPT';
            END IF;
        END $$;
    """)
    op.execute("""
        DO $$ 
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_enum e
                JOIN pg_type t ON e.enumtypid = t.oid
                JOIN pg_namespace n ON t.typnamespace = n.oid
                WHERE e.enumlabel = 'RATING_REQUEST' 
                AND t.typname = 'alerttype'
                AND n.nspname = 'public'
            ) THEN
                ALTER TYPE alerttype ADD VALUE 'RATING_REQUEST';
            END IF;
        END $$;
    """)


def downgrade() -> None:
    """Downgrade schema."""
    # Note: PostgreSQL doesn't support removing enum values directly
    # You would need to recreate the enum type if downgrading is needed
    # For now, this is a no-op as enum value removal is complex
    pass
