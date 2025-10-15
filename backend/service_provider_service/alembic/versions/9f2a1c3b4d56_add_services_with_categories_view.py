"""
Add services_with_categories view for efficient service/category joins

Revision ID: 9f2a1c3b4d56
Revises: 7c05b795cd07
Create Date: 2025-10-13 12:00:00.000000
"""

from alembic import op

# revision identifiers, used by Alembic.
revision = '9f2a1c3b4d56'
down_revision = '7c05b795cd07'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        CREATE OR REPLACE VIEW service_providers.services_with_categories AS
        SELECT 
            s.id            AS service_id,
            s.name          AS service_name,
            s.description   AS service_description,
            s.requirements  AS service_requirements,
            s.created_at    AS service_created_at,
            s.category_id   AS service_category_id,
            sc.name         AS service_category_name
        FROM service_providers.services s
        LEFT JOIN service_providers.service_categories sc
          ON s.category_id = sc.id;
        """
    )


def downgrade() -> None:
    op.execute("DROP VIEW IF EXISTS service_providers.services_with_categories;")


