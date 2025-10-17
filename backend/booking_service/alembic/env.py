
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool
from alembic import context

# --- 🔹 1. Import your service’s models here ---
from models import booking 
# Example for vehicles service:
from core.db import Base  

# This is the Alembic Config object
config = context.config

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# --- 🔹 2. Set the target metadata (SQLAlchemy Base) ---
target_metadata = Base.metadata

# --- 🔹 3. Change this per service (schema name) ---
SERVICE_SCHEMA = "bookings"   # 👈 change per service


def include_object(object, name, type_, reflected, compare_to):
    """Only include this service’s schema objects in migrations."""
    if type_ == "table" and object.schema != SERVICE_SCHEMA:
        return False
    return True


def run_migrations_offline():
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},

        # 👇 isolate version tracking per schema
        version_table="alembic_version",
        version_table_schema=SERVICE_SCHEMA,
        include_schemas=True,
        include_object=include_object,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    """Run migrations in 'online' mode."""
    # Get database URL from environment variable
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise ValueError("DATABASE_URL environment variable is not set")
    
    # Override the sqlalchemy.url in the config
    config.set_main_option("sqlalchemy.url", database_url)
    
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,

            # 👇 isolate version tracking per schema
            version_table="alembic_version",
            version_table_schema=SERVICE_SCHEMA,
            include_schemas=True,
            include_object=include_object,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
