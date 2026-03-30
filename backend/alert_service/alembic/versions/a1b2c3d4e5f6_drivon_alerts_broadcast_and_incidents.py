"""drivon_alerts_broadcast_and_incidents

Revision ID: a1b2c3d4e5f6
Revises: 48d05b247c5c
Create Date: 2026-03-27 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op

revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '48d05b247c5c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── 1. Add Drivon Alerts enum values to alerttype ─────────────────────────
    for label in ('WEATHER', 'SECURITY', 'SAFETY', 'ROUTE_ALERT', 'FLEET_ALERT'):
        op.execute(f"""
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_enum e
                    JOIN pg_type t ON e.enumtypid = t.oid
                    JOIN pg_namespace n ON t.typnamespace = n.oid
                    WHERE e.enumlabel = '{label}'
                    AND t.typname = 'alerttype'
                    AND n.nspname = 'public'
                ) THEN
                    ALTER TYPE alerttype ADD VALUE '{label}';
                END IF;
            END $$;
        """)

    # ── 2. Create broadcastalertstatus enum ───────────────────────────────────
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'broadcastalertstatus') THEN
                CREATE TYPE broadcastalertstatus AS ENUM ('draft', 'active', 'expired', 'cancelled');
            END IF;
        END $$;
    """)

    # ── 3. Create incidenttype enum ───────────────────────────────────────────
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'incidenttype') THEN
                CREATE TYPE incidenttype AS ENUM ('security', 'road', 'weather', 'vehicle', 'other');
            END IF;
        END $$;
    """)

    # ── 4. Create incidentstatus enum ─────────────────────────────────────────
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'incidentstatus') THEN
                CREATE TYPE incidentstatus AS ENUM ('submitted', 'reviewing', 'resolved', 'dismissed');
            END IF;
        END $$;
    """)

    # ── 5. Create broadcast_alerts table (raw SQL avoids SQLAlchemy re-creating enums) ──
    op.execute("""
        CREATE TABLE IF NOT EXISTS alerts.broadcast_alerts (
            id                VARCHAR      NOT NULL PRIMARY KEY,
            title             VARCHAR(255) NOT NULL,
            message           TEXT         NOT NULL,
            type              alerttype    NOT NULL,
            priority          INTEGER      NOT NULL DEFAULT 2,
            channels          JSONB        NOT NULL DEFAULT '[]',
            target_audience   VARCHAR               DEFAULT 'all',
            latitude          VARCHAR,
            longitude         VARCHAR,
            radius_km         INTEGER,
            status            broadcastalertstatus  DEFAULT 'draft',
            active_from       TIMESTAMPTZ,
            expires_at        TIMESTAMPTZ,
            created_by_admin  VARCHAR,
            source            VARCHAR,
            action_url        VARCHAR,
            action_text       VARCHAR,
            created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
            updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("CREATE INDEX IF NOT EXISTS ix_broadcast_alerts_status ON alerts.broadcast_alerts (status);")
    op.execute("CREATE INDEX IF NOT EXISTS ix_broadcast_alerts_type   ON alerts.broadcast_alerts (type);")

    # ── 6. Create incident_reports table ──────────────────────────────────────
    op.execute("""
        CREATE TABLE IF NOT EXISTS alerts.incident_reports (
            id             VARCHAR      NOT NULL PRIMARY KEY,
            user_id        INTEGER      NOT NULL,
            incident_type  incidenttype NOT NULL,
            title          VARCHAR(255) NOT NULL,
            description    TEXT         NOT NULL,
            latitude       VARCHAR,
            longitude      VARCHAR,
            location_text  VARCHAR,
            media_urls     JSONB                 DEFAULT '[]',
            status         incidentstatus        DEFAULT 'submitted',
            admin_notes    TEXT,
            created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
            updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
        );
    """)
    op.execute("CREATE INDEX IF NOT EXISTS ix_incident_reports_user_id ON alerts.incident_reports (user_id);")
    op.execute("CREATE INDEX IF NOT EXISTS ix_incident_reports_status  ON alerts.incident_reports (status);")


def downgrade() -> None:
    op.drop_table('incident_reports', schema='alerts')
    op.drop_table('broadcast_alerts', schema='alerts')
    # Note: PostgreSQL enum values cannot be removed; enums left intact on downgrade
