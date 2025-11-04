"""add log_id to provider_ratings

Revision ID: a1b2c3d4e5f6
Revises: 217e8a26097f
Create Date: 2025-11-04 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '217e8a26097f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add log_id column to provider_ratings table
    op.add_column('provider_ratings', 
        sa.Column('log_id', sa.String(), nullable=True),
        schema='service_providers'
    )
    # Add index on log_id for faster lookups
    op.create_index(
        'ix_service_providers_provider_ratings_log_id',
        'provider_ratings',
        ['log_id'],
        schema='service_providers'
    )
    # Add updated_at column for tracking rating updates
    op.add_column('provider_ratings',
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('now()'), nullable=True),
        schema='service_providers'
    )


def downgrade() -> None:
    op.drop_index('ix_service_providers_provider_ratings_log_id', table_name='provider_ratings', schema='service_providers')
    op.drop_column('provider_ratings', 'updated_at', schema='service_providers')
    op.drop_column('provider_ratings', 'log_id', schema='service_providers')

