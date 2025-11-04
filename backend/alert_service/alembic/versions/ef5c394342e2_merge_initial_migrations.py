"""merge_initial_migrations

Revision ID: ef5c394342e2
Revises: 37f1fda05547, 8a8549c1b995
Create Date: 2025-11-04 10:59:42.471715

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ef5c394342e2'
down_revision: Union[str, Sequence[str], None] = ('37f1fda05547', '8a8549c1b995')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
