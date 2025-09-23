from alembic import context
from sqlalchemy import engine_from_config, pool
from logging.config import fileConfig
import sys, os

# Add parent directory so core can be found
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from core.db import Base
from models.vehicles import Vehicle

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata
SERVICE_SCHEMA = "vehicles"

def include_object(object, name, type_, reflected, compare_to):
    if type_ == "table" and object.schema != SERVICE_SCHEMA:
        return False
    return True

def run_migrations_offline():
    context.configure(
        url=config.get_main_option("sqlalchemy.url"),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        version_table="alembic_version",
        version_table_schema=SERVICE_SCHEMA,
        include_schemas=True,
        include_object=include_object,
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            version_table="alembic_version",
            version_table_schema=SERVICE_SCHEMA,
            include_schemas=True,
            include_object=include_object,
        )

        # ✅ Only run actual migrations if this is NOT a stamp command
        if getattr(config.cmd_opts, "cmd", None) != "stamp":
            with context.begin_transaction():
                context.run_migrations()
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
